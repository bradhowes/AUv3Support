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
  private let log = Shared.logger("FilterAudioUnit")

  public enum Failure: Swift.Error {
    case statusError(OSStatus)
    case unableToInitialize(String)
  }

  /// The signal processing kernel that performs the rendering of audio samples
  private var kernel: AudioRenderer?
  /// Runtime parameter definitions for the audio unit
  private var parameters: ParameterSource?

  /// The associated view controller for the audio unit that shows the controls
  public weak var viewConfigurationManager: AudioUnitViewConfigurationManager?

  /// Initial sample rate
  private let sampleRate: Double = 44100.0
  /// Maximum number of channels to support
  private let maxNumberOfChannels: UInt32 = 8

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

    guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
      os_log(.error, log: log, "failed to create AVAudioFormat format")
      throw Failure.unableToInitialize(String(describing: AVAudioFormat.self))
    }

    os_log(.debug, log: log, "format: %{public}s", format.description)
    inputBus = try AUAudioUnitBus(format: format)
    inputBus.maximumChannelCount = maxNumberOfChannels

    os_log(.debug, log: log, "creating output bus")
    outputBus = try AUAudioUnitBus(format: format)
    outputBus.maximumChannelCount = maxNumberOfChannels

    try super.init(componentDescription: componentDescription, options: options)
    
    os_log(.debug, log: log, "type: %{public}s, subtype: %{public}s, manufacturer: %{public}s flags: %x",
           componentDescription.componentType.stringValue,
           componentDescription.componentSubType.stringValue,
           componentDescription.componentManufacturer.stringValue,
           componentDescription.componentFlags)
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
    os_log(.debug, log: log, "configure BEGIN")

    self.kernel = kernel
    parameters.parameterTree.implementorValueProvider = kernel.get(_:)
    parameters.parameterTree.implementorValueObserver = kernel.set(_:value:)
    self.parameters = parameters

    // At start, configure effect to do something interesting. Hosts can and should update the effect state after it is
    // initialized via `fullState` attribute.
    currentPreset = parameters.factoryPresets.first

    os_log(.debug, log: log, "configure END")
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
    get { parameters?.parameterTree }
    set { fatalError("attempted to set new parameterTree") }
  }
  /// Factory presets for the filter
  override public var factoryPresets: [AUAudioUnitPreset]? { parameters?.factoryPresets }
  /// Announce support for user presets
  override public var supportsUserPresets: Bool { true }
  /// Obtain the current bypass setting
  override public var shouldBypassEffect: Bool { didSet { kernel?.setBypass(shouldBypassEffect); }}
  /// Announce that the filter can work directly on upstream sample buffers
  override public var canProcessInPlace: Bool { true }

  /// Active preset management. Setting a non-nil value updates the components parameters to hold the values found in
  /// the preset. Factory presets are done internally via the `ParameterSource.usePreset` function. User presets rely
  /// on AUAudioUnit functionality to change the `AUParameter` values in the `AUParameterTree` via the `fullState`
  /// property.
  @objc dynamic override public var currentPreset: AUAudioUnitPreset? {
    get {
      os_log(.info, log: log, "get currentPreset - %{public}s", _currentPreset.descriptionOrNil)
      return _currentPreset
    }
    set {
      os_log(.info, log: log, "set currentPreset - %{public}s", newValue.descriptionOrNil)
      guard _currentPreset != newValue else {
        return
      }

      if let preset = newValue {
        if preset.number >= 0 {
          os_log(.info, log: log, "factoryPreset %d", preset.number)
          _currentPreset = preset
          os_log(.info, log: log, "updating parameters")
          parameters?.useFactoryPreset(preset)
          return
        }

        os_log(.info, log: log, "userPreset %d", preset.number)
        if let state = try? presetState(for: preset) {
          os_log(.info, log: log, "state: %{public}s", state.debugDescription)
          fullState = state
          _currentPreset = preset
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
      os_log(.info, log: log, "fullState GET")

      // The AUAudioUnit property will return a binary encoding of the parameter tree. It is decodable, but still the
      // format has not been published. For now, we will use it but a better implementation would be to encode/decode
      // our own format and rely on that instead of the binary blob that AUAudioUnit provides us.
      var value = super.fullState ?? [String: Any]()
      parameters?.storeParameters(into: &value)
      if let preset = _currentPreset {

        // Record into the state the active preset name and number. This will allow us to recover it later when given
        // a fullState dictionary.
        value[kAUPresetNameKey] = preset.name
        value[kAUPresetNumberKey] = preset.number
      }
      os_log(.info, log: log, "value: %{public}s", value.description)
      return value
    }
    set {
      os_log(.info, log: log, "fullState SET")
      os_log(.info, log: log, "value: %{public}s", newValue.descriptionOrNil)
      super.fullState = newValue

      if let state = newValue,
         let name = state[kAUPresetNameKey] as? String,
         let number = state[kAUPresetNumberKey] as? NSNumber {
        os_log(.info, log: log, "name %{public}s number %d", name, number.intValue)
        _currentPreset = AUAudioUnitPreset(number: number.intValue, name: name)
      } else {
        _currentPreset = nil
      }
    }
  }
}

// MARK: - Rendering

extension FilterAudioUnit {

  /**
   Take notice of input/output bus formats and prepare for rendering. If there are any errors getting things ready,
   routine should `setRenderResourcesAllocated(false)`.
   */
  override public func allocateRenderResources() throws {
    os_log(.info, log: log, "allocateRenderResources BEGIN")
    guard let kernel = kernel else { fatalError("FilterAudioUnit not configured with kernel") }
    guard let parameters = parameters else { fatalError("FilterAudioUnit not configured with parameter source") }

    try super.allocateRenderResources()

    os_log(.debug, log: log, "inputBus format: %{public}s", inputBus.format.description)
    os_log(.debug, log: log, "outputBus format: %{public}s", outputBus.format.description)
    os_log(.debug, log: log, "maximumFramesToRender: %d", maximumFramesToRender)

    if outputBus.format.channelCount != inputBus.format.channelCount {
      os_log(.error, log: log, "unequal channel count")
      setRenderResourcesAllocated(false)

      // NOTE: changing this to something else will cause `auval` to emit the following:
      //   WARNING: Can Initialize Unit to un-supported num channels:InputChan:1, OutputChan:2
      //
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
    }

    kernel.setRenderingFormat(outputBus.format, maxFramesToRender: maximumFramesToRender)

    // Configure parameter value setting to use internal `scheduleParameterBlock` instead of direct updates to kernel.
    let rampDurationInSamples = AUAudioFrameCount(30)
    let scheduleParameter = scheduleParameterBlock
    parameters.parameterTree.implementorValueObserver = { param, value in
      scheduleParameter(AUEventSampleTimeImmediate, rampDurationInSamples, param.address, value);
    }

    os_log(.info, log: log, "allocateRenderResources END")
  }

  /**
   Rendering has stopped -- tear down stuff that was supporting it.
   */
  override public func deallocateRenderResources() {
    os_log(.debug, log: log, "deallocateRenderResources BEGIN")
    guard let kernel = kernel else { fatalError("FilterAudioUnit not configured with kernel") }
    guard let parameters = parameters else { fatalError("FilterAudioUnit not configured with parameter source") }

    super.deallocateRenderResources()

    kernel.renderingStopped()
    parameters.parameterTree.implementorValueObserver = kernel.set(_:value:)

    os_log(.debug, log: log, "deallocateRenderResources END")
  }
  
  override public var internalRenderBlock: AUInternalRenderBlock {
    os_log(.info, log: log, "internalRenderBlock BEGIN")
    guard let kernel = kernel else { fatalError("nil kernel") }
    return kernel.internalRenderBlock() // (transportStateBlock)
  }
}

// MARK: - Host View Management

extension FilterAudioUnit {

  override public func parametersForOverview(withCount: Int) -> [NSNumber] {
    parameters?.parameters[0..<withCount].map { NSNumber(value: $0.address) } ?? []
  }

  override public func supportedViewConfigurations(_ available: [AUAudioUnitViewConfiguration]) -> IndexSet {
    viewConfigurationManager?.supportedViewConfigurations(available) ?? IndexSet(integersIn: 0..<available.count)
  }
  
  override public func select(_ viewConfiguration: AUAudioUnitViewConfiguration) {
    viewConfigurationManager?.selectViewConfiguration(viewConfiguration)
  }
}
