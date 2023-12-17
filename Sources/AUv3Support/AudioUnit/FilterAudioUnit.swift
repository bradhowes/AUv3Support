// Copyright © 2022 Brad Howes. All rights reserved.

import AudioToolbox
import AVFoundation
import CoreAudioKit
import os.log

/**
 Derivation of AUAudioUnit that provides a Swift container for the C++ Kernel (by way of the Obj-C Bridge adapter).
 Provides for factory presets and user preset management. This basically a generic container for audio filtering as all
 of the elements specific to a particular filter/effect are found elsewhere.

 The actual filtering logic resides in the Kernel C++ code which is abstracted away as an `AudioRenderer` entity.
 Similarly, parameters for controlling the filter are provided by an abstract `ParameterSource` entity.
 */
public final class FilterAudioUnit: AUAudioUnit {

  private let log: OSLog = OSLog(subsystem: "com.braysoftware.AUv3Support", category: "FilterAudioUnit")

  /// Initial sample rate when initialized
  static private let defaultSampleRate: Double = 44100.0
  /// Maximum number of channels to support per audio bus
  static private let audioBusMaxNumberOfChannels: UInt32 = 8
  /// Default channel layout to use in each audio bus
  static private let audioBusChannelLayout = AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_Stereo)!
  /// Default audio format to use in each audio bus
  static private let audioBusFormat = AVAudioFormat(standardFormatWithSampleRate: defaultSampleRate,
                                                    channelLayout: audioBusChannelLayout)
  /// Create an AUAudioUnitBus using the default audio format
  static func makeAudioBus() throws -> AUAudioUnitBus {
    let bus = try AUAudioUnitBus(format: audioBusFormat)
    bus.maximumChannelCount = audioBusMaxNumberOfChannels
    return bus
  }

  public enum Failure: Swift.Error {
    case statusError(OSStatus)
    case unableToInitialize(String)
  }

  /// The signal processing kernel that performs the rendering of audio samples.
  private var kernel: AudioRenderer!
  /// Runtime parameter definitions for the audio unit
  private var parameters: ParameterSource!

  /// The associated view controller for the audio unit that shows the controls
  public weak var viewConfigurationManager: AudioUnitViewConfigurationManager?

  /// The active preset in use. This is the backing value for the `currentPreset` property.
  private var _currentPreset: AUAudioUnitPreset? {
    willSet { willChangeValue(for: \.currentPreset) }
    didSet { didChangeValue(for: \.currentPreset) }
  }

  private var inputBus: AUAudioUnitBus
  private var outputBus: AUAudioUnitBus
  private lazy var _inputBusses: AUAudioUnitBusArray = .init(audioUnit: self, busType: .input, busses: [inputBus])
  private lazy var _outputBusses: AUAudioUnitBusArray = .init(audioUnit: self, busType: .output, busses: [outputBus])

  /**
   Create a new audio unit asynchronously.
   
   - parameter componentDescription: the component to instantiate
   - parameter options: options for instantiation
   - parameter completionHandler: closure to invoke upon creation or error
   */
  override public class func instantiate(with componentDescription: AudioComponentDescription,
                                         options: AudioComponentInstantiationOptions = [],
                                         completionHandler: @escaping (AUAudioUnit?, Error?) -> Void) {
    do {
      let auAudioUnit = try FilterAudioUnit(componentDescription: componentDescription, options: options)
      completionHandler(auAudioUnit, nil)
    } catch {
      completionHandler(nil, error)
    }
  }

  /**
   Construct new instance, throwing exception if there is an error doing so.
   
   - parameter componentDescription: the component to instantiate
   - parameter options: options for instantiation
   */
  override public init(componentDescription: AudioComponentDescription,
                       options: AudioComponentInstantiationOptions = []) throws {
    os_log(.info, log: log, "init - BEGIN %ld", componentDescription.componentFlags)

    // Treat all 1s componentFlagsMask as error -- used for testing. NOTE: at least on macOS 13.0.1 this can be non-zero
    // (30) which is counter to what the documentation states.
    if componentDescription.componentFlags == UInt32.max {
      throw Failure.unableToInitialize(String(describing: AVAudioFormat.self))
    }

    inputBus = try Self.makeAudioBus()
    outputBus = try Self.makeAudioBus()

    try super.init(componentDescription: componentDescription, options: options)
    os_log(.info, log: log, "init - END")
  }

  deinit {
    os_log(.info, log: log, "deinit")
  }
}

// MARK: - Configuration

extension FilterAudioUnit {

  /**
   Install the entity that provides the AUParameter definitions for the AUParameterTree (it also may hold factory
   presets) and the entity that performs the actual audio sample rendering for the audio unit.

   - parameter parameters: the parameter source to use
   - parameter kernel: the rendering kernel to use
   */
  public func configure(parameters: ParameterSource, kernel: AudioRenderer) {
    self.parameters = parameters
    self.kernel = kernel

    // Install handler that provides a value for an AUParameter in the parameter tree.
    parameters.parameterTree.implementorValueProvider = self.kernel.parameterValueProviderBlock()

    // Install handler that updates an AUParameter in the parameter tree with a new value.
    parameters.parameterTree.implementorValueObserver = self.kernel.parameterValueObserverBlock()

    // At start, configure effect to do something interesting. Hosts can and should update the effect state after it is
    // initialized via `fullState` attribute.
    currentPreset = parameters.factoryPresets.first
  }
}

// MARK: - AUv3 Properties

extension FilterAudioUnit {

  /// The input busses supported by the component. We only support one.
  override public var inputBusses: AUAudioUnitBusArray { _inputBusses }

  /// The output busses supported by the component. We only support one.
  override public var outputBusses: AUAudioUnitBusArray { _outputBusses }

  /// Parameter tree containing filter parameters that are exposed for external control. No setting is allowed.
  override public var parameterTree: AUParameterTree? {
    get { parameters.parameterTree }
    set {}
  }

  /// Factory presets for the filter
  override public var factoryPresets: [AUAudioUnitPreset]? { parameters.factoryPresets }
  /// Announce support for user presets
  override public var supportsUserPresets: Bool { true }
  /// Announce that the filter can work directly on upstream sample buffers
  override public var canProcessInPlace: Bool { true }

  /// Active preset management. Setting a non-nil value updates the components parameters to hold the values found in
  /// the preset. Factory presets are done internally via the `ParameterSource.usePreset` function. User presets rely
  /// on AUAudioUnit functionality to change the `AUParameter` values in the `AUParameterTree` via the `fullState`
  /// property.
  @objc dynamic override public var currentPreset: AUAudioUnitPreset? {
    get {
      return _currentPreset
    }
    set {
      guard _currentPreset != newValue else { return }

      if let preset = newValue {
        if preset.number >= 0 {
          _currentPreset = preset
          parameters.useFactoryPreset(preset)
          return
        }
        else if let state = try? presetState(for: preset) {
          fullState = state
          parameters.useUserPreset(from: state)
          return
        }
      }
      _currentPreset = nil
    }
  }

  /**
   Clear `currentPreset` if it holds a factory preset.
   */
  public func clearCurrentPresetIfFactoryPreset() {
    if let preset = _currentPreset, preset.number >= 0 {
      _currentPreset = nil
    }
  }

  /// Add current preset name and number to the state that is returned.
  override public var fullState: [String : Any]? {
    get {

      // The AUAudioUnit property will return a binary encoding of the parameter tree. It is decodable, but still the
      // format has not been published. For now, we will use it but a better implementation would be to encode/decode
      // our own format and rely on that instead of the binary blob that AUAudioUnit provides us.
      var value = super.fullState ?? [String: Any]()
      parameters.storeParameters(into: &value)
      if let preset = _currentPreset {

        // Record into the state the active preset name and number. This will allow us to recover it later when given
        // a fullState dictionary.
        value[kAUPresetNameKey] = preset.name
        value[kAUPresetNumberKey] = preset.number
      }
      return value
    }
    set {
      super.fullState = newValue

      if let state = newValue,
         let name = state[kAUPresetNameKey] as? String,
         let number = state[kAUPresetNumberKey] as? NSNumber {
        if _currentPreset?.number != number.intValue {
          _currentPreset = AUAudioUnitPreset(number: number.intValue, name: name)
        }
      } else {
        currentPreset = nil
      }
    }
  }
}

// MARK: - Rendering

extension FilterAudioUnit {

  /// The bypass setting is bridged with the v2 property. We detect when it changes here and forward it to the kernel.
  /// A better way might be to integrate it with the AUParameterTree with a standard bypass parameter.
  override public var shouldBypassEffect: Bool { didSet { kernel.setBypass(shouldBypassEffect); }}

  /**
   Take notice of input/output bus formats and prepare for rendering. If there are any errors getting things ready,
   routine should `setRenderResourcesAllocated(false)`.
   */
  override public func allocateRenderResources() throws {
    os_log(.info, log: log, "allocateRenderResources - BEGIN")
    precondition(kernel != nil)

    try super.allocateRenderResources()

    if outputBus.format.channelCount != inputBus.format.channelCount {
      setRenderResourcesAllocated(false)

      // NOTE: changing this to something else will cause `auval` to emit the following:
      //   WARNING: Can Initialize Unit to un-supported num channels:InputChan:1, OutputChan:2
      //
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
    }

    // Acquire the sample rate and additional format parameter from the output bus we write output to. The host can
    // change the format at will before calling allocateRenderResources.
    kernel.setRenderingFormat(outputBusses.count, format: outputBus.format, maxFramesToRender: maximumFramesToRender)

    os_log(.info, log: log, "allocateRenderResources - END")
  }

  /**
   Rendering has stopped -- tear down stuff that was supporting it.
   */
  override public func deallocateRenderResources() {
    precondition(kernel != nil)
    super.deallocateRenderResources()
    kernel.deallocateRenderResources()
  }

  /// Provide the rendering block that will provide rendered samples.
  override public var internalRenderBlock: AUInternalRenderBlock {
    os_log(.info, log: log, "internalRenderBlock - BEGIN")
    precondition(kernel != nil)
    let transportStateBlock = self.transportStateBlock
    return kernel.internalRenderBlock(transportStateBlock)
  }
}

// MARK: - Host View Management

extension FilterAudioUnit {

  override public func parametersForOverview(withCount: Int) -> [NSNumber] {
    parameters.parameters[0..<withCount].map { NSNumber(value: $0.address) }
  }

  override public func supportedViewConfigurations(_ available: [AUAudioUnitViewConfiguration]) -> IndexSet {
    viewConfigurationManager?.supportedViewConfigurations(available) ?? IndexSet(integersIn: 0..<available.count)
  }
  
  override public func select(_ viewConfiguration: AUAudioUnitViewConfiguration) {
    viewConfigurationManager?.selectViewConfiguration(viewConfiguration)
  }
}
