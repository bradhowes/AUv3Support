// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import CoreAudioKit
import AUv3Support
import os.log

/**
 Errors that can come from AudioUnitHost.
 */
public enum AudioUnitLoaderError: Error {
  /// Unexpected nil AUAudioUnit (most likely never can happen)
  case nilAudioUnit
  /// Unexpected nil ViewController from AUAudioUnit request
  case nilViewController
  /// Failed to locate component matching given AudioComponentDescription
  case componentNotFound
  /// Error from Apple framework (CoreAudio, AVFoundation, etc.)
  case framework(error: Error)
  /// String describing the error case.
  public var description: String {
    switch self {
    case .nilAudioUnit: return "Failed to obtain a usable audio unit instance."
    case .nilViewController: return "Failed to obtain a usable view controller from the instantiated audio unit."
    case .componentNotFound: return "Failed to locate the right AUv3 component to instantiate."
    case .framework(let err): return "Framework error: \(err.localizedDescription)"
    }
  }
}

/**
 Delegation protocol for AudioUnitHost class.
 */
public protocol AudioUnitLoaderDelegate: AnyObject {
  /**
   Notification that the UIViewController in the AudioUnitHost has a wired AUAudioUnit
   */
  func connected(audioUnit: AVAudioUnit, viewController: ViewController)

  /**
   Notification that there was a problem instantiating the audio unit or its view controller

   - parameter error: the error that was encountered
   */
  func failed(error: AudioUnitLoaderError)
}

/**
 Simple hosting container for the FilterAudioUnit when used in an application. Loads the view controller for the
 AudioUnit and then instantiates the audio unit itself. Finally, it wires the AudioUnit with SimplePlayEngine to
 send audio samples to the AudioUnit. Note that this class has no knowledge of any classes other than what Apple
 provides.
 */
public final class AudioUnitLoader {
  private let log: OSLog

  /// AudioUnit controlled by the view controller
  public private(set) var avAudioUnit: AVAudioUnit?

  public var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }

  /// View controller for the AudioUnit interface
  public private(set) var viewController: ViewController?

  /// True if the audio engine is currently playing
  public var isPlaying: Bool { playEngine.isPlaying }

  /// Delegate to signal when everything is wired up.
  public weak var delegate: AudioUnitLoaderDelegate? { didSet { notifyDelegate() } }

  private let lastStateKey = "lastStateKey"
  private let lastPresetNumberKey = "lastPresetNumberKey"

  private let playEngine: SimplePlayEngine
  private let locateQueue: DispatchQueue
  private let componentDescription: AudioComponentDescription

  private var notificationObserverToken: NSObjectProtocol?
  private var creationError: AudioUnitLoaderError? { didSet { notifyDelegate() } }
  private var detectionTimer: Timer?

  /**
   The loops that are available.
   */
  public enum SampleLoop: String {
    case sample1 = "sample1.wav"
    case sample2 = "sample2.caf"
  }

  /**
   Create a new instance that will hopefully create a new AUAudioUnit and a view controller for its control view.

   - parameter componentDescription: the definition of the AUAudioUnit to create
   - parameter loop: the loop to play when the engine is playing
   */
  public init(name: String, componentDescription: AudioComponentDescription, loop: SampleLoop) {
    self.log = .init(subsystem: name, category: "AudioUnitLoader")
    self.locateQueue = .init(label: name + ".LocateQueue", qos: .userInitiated)
    self.playEngine = .init(audioFileName: loop.rawValue)
    self.componentDescription = componentDescription
    locate()
  }

  /**
   Use AVAudioUnitComponentManager to locate the AUv3 component we want. This is done asynchronously in the background.
   If the component we want is not found, start listening for notifications from the AVAudioUnitComponentManager for
   updates and try again.
   */
  private func locate() {
    os_log(.debug, log: log, "locate")
    locateQueue.async { [weak self] in
      guard let self = self else { return }

      let description = AudioComponentDescription(componentType: self.componentDescription.componentType,
                                                  componentSubType: 0,
                                                  componentManufacturer: 0,
                                                  componentFlags: 0,
                                                  componentFlagsMask: 0)

      let components = AVAudioUnitComponentManager.shared().components(matching: description)
      os_log(.debug, log: self.log, "locate: found %d", components.count)

      for each in components {
        each.audioComponentDescription.log(self.log, type: .debug)
        if each.audioComponentDescription.componentManufacturer == self.componentDescription.componentManufacturer,
           each.audioComponentDescription.componentType == self.componentDescription.componentType,
           each.audioComponentDescription.componentSubType == self.componentDescription.componentSubType {
          os_log(.debug, log: self.log, "found match")
          DispatchQueue.main.async {
            self.createAudioUnit(each.audioComponentDescription)
          }
          return
        }
      }

      DispatchQueue.main.async {
        self.checkAgain()
      }
    }
  }

  /**
   Begin listening for updates from the AVAudioUnitComponentManager. When we get one, stop listening and attempt to
   locate the AUv3 component we want.
   */
  private func checkAgain() {
    os_log(.debug, log: log, "checkAgain")
    let center = NotificationCenter.default

    detectionTimer?.invalidate()
    detectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
      self.creationError = AudioUnitLoaderError.componentNotFound
    }

    notificationObserverToken = center.addObserver(
      forName: AVAudioUnitComponentManager.registrationsChangedNotification, object: nil, queue: nil
    ) { [weak self] _ in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "checkAgain: notification")
      let token = self.notificationObserverToken!
      self.notificationObserverToken = nil
      center.removeObserver(token)
      self.detectionTimer?.invalidate()
      self.locate()
    }
  }

  /**
   Create the desired component using the AUv3 API
   */
  private func createAudioUnit(_ componentDescription: AudioComponentDescription) {
    os_log(.debug, log: log, "createAudioUnit")
    guard avAudioUnit == nil else { return }

#if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
#else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
#endif

    AVAudioUnit.instantiate(with: componentDescription, options: options) { [weak self] avAudioUnit, error in
      guard let self = self else { return }
      if let error = error {
        os_log(.error, log: self.log, "createAudioUnit: error - %{public}s", error.localizedDescription)
        self.creationError = .framework(error: error)
        return
      }

      guard let avAudioUnit = avAudioUnit else {
        os_log(.error, log: self.log, "createAudioUnit: nil avAudioUnit")
        self.creationError = AudioUnitLoaderError.nilAudioUnit
        return
      }

      DispatchQueue.main.async {
        self.createViewController(avAudioUnit)
      }
    }
  }

  /**
   Create the component's view controller to embed in the host view.

   - parameter avAudioUnit: the AVAudioUnit that was instantiated
   */
  private func createViewController(_ avAudioUnit: AVAudioUnit) {
    os_log(.debug, log: log, "createViewController")
    avAudioUnit.auAudioUnit.requestViewController { [weak self] controller in
      guard let self = self else { return }
      guard let controller = controller else {
        self.creationError = AudioUnitLoaderError.nilViewController
        return
      }
      os_log(.debug, log: self.log, "view controller type - %{public}s", String(describing: type(of: controller)))
      self.wireAudioUnit(avAudioUnit, controller)
    }
  }

  /**
   Finalize creation of the AUv3 component. Connect to the audio engine and notify the main view controller that
   everything is done.

   - parameter avAudioUnit: the audio unit that was created
   - parameter viewController: the view controller that was created
   */
  private func wireAudioUnit(_ avAudioUnit: AVAudioUnit, _ viewController: ViewController) {
    self.avAudioUnit = avAudioUnit
    self.viewController = viewController

    playEngine.connectEffect(audioUnit: avAudioUnit)
    notifyDelegate()
  }

  private func notifyDelegate() {
    os_log(.debug, log: log, "notifyDelegate")
    if let creationError = creationError {
      os_log(.debug, log: log, "error: %{public}s", creationError.localizedDescription)
      DispatchQueue.main.async { self.delegate?.failed(error: creationError) }
    } else if let avAudioUnit = avAudioUnit, let viewController = viewController {
      os_log(.debug, log: log, "success")
      DispatchQueue.main.async { self.delegate?.connected(audioUnit: avAudioUnit, viewController: viewController) }
    }
  }
}

public extension AudioUnitLoader {

  /**
   Save the current state of the AUv3 component to UserDefaults for future restoration. Saves the value from
   `fullStateForDocument` and the number of the preset that is in `currentPreset` if non-nil.
   */
  func save() {
    guard let audioUnit = auAudioUnit else { return }
    locateQueue.async { [weak self] in self?.doSave(audioUnit) }
  }

  private func doSave(_ audioUnit: AUAudioUnit) {

    // Theoretically, we only need to save the full state if `currentPreset` is nil. However, it is possible that the
    // preset is a user preset and is removed some time in the future by another application. So we always safe the
    // full state here (if available).
    //
    if let lastState = audioUnit.fullStateForDocument {
      UserDefaults.standard.set(lastState, forKey: lastStateKey)
    } else {
      UserDefaults.standard.removeObject(forKey: lastStateKey)
    }

    // Save the number of the current preset.
    if let lastPresetNumber = audioUnit.currentPreset?.number {
      UserDefaults.standard.set(lastPresetNumber, forKey: lastPresetNumberKey)
    } else {
      UserDefaults.standard.removeObject(forKey: lastPresetNumberKey)
    }
  }

  /**
   Restore the state of the AUv3 component using values found in UserDefaults.
   */
  func restore() {
    guard let audioUnit = auAudioUnit else { return }
    locateQueue.async { [weak self] in self?.doRestore(audioUnit) }
  }

  private func doRestore(_ audioUnit: AUAudioUnit) {

    // Fetch all of the values to use before modifying AUv3 state.
    let lastState = UserDefaults.standard.dictionary(forKey: lastStateKey)
    let lastPresetNumber = UserDefaults.standard.object(forKey: lastPresetNumberKey)

    // Restore state of component
    if let lastState = lastState {
      audioUnit.fullStateForDocument = lastState
    }

    // Restore state of the `currentPreset` value.
    if let lastPresetNumber = lastPresetNumber as? NSNumber {

      // Locate the preset with the saved number. If number is negative, it is a user preset; else factory preset.
      // If not found, set `currentPreset` to nil.
      let presetNumber = lastPresetNumber.intValue
      audioUnit.currentPreset = (presetNumber >= 0 ? audioUnit.factoryPresetsNonNil : audioUnit.userPresets)
        .first { $0.number == presetNumber }
    } else {
      audioUnit.currentPreset = nil
    }
  }
}

public extension AudioUnitLoader {
  /**
   Start/stop audio engine

   - returns: true if playing
   */
  @discardableResult
  func togglePlayback() -> Bool { playEngine.startStop() }

  /**
   The world is being torn apart. Stop any asynchronous eventing from happening in the future.
   */
  func cleanup() {
    playEngine.stop()
  }
}
