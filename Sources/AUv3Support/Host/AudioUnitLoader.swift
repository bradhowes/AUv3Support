// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import os.log

/**
 Errors that can come from AudioUnitLoader.
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
 Delegation protocol for AudioUnitLoader class.
 */
public protocol AudioUnitLoaderDelegate: AnyObject {
  /**
   Notification that the view controller in the AudioUnitHost has a wired AUAudioUnit
   */
  func connected(audioUnit: AVAudioUnit, viewController: ViewController)

  /**
   Notification that there was a problem instantiating the audio unit or its view controller

   - parameter error: the error that was encountered
   */
  func failed(error: AudioUnitLoaderError)
}

/**
 Simple loader for the FilterAudioUnit when used in an application. Loads the view controller for the
 AudioUnit and then instantiates the audio unit itself. Finally, it wires the AudioUnit with SimplePlayEngine to
 send audio samples to the AudioUnit. Note that this class has no knowledge of any classes other than what Apple
 provides.
 */
public final class AudioUnitLoader: NSObject {
  private static let lastStateKey = "lastStateKey"

  private let log: OSLog

  /// Delegate to signal when everything is wired up.
  public weak var delegate: AudioUnitLoaderDelegate? { didSet { notifyDelegate() } }

  private var avAudioUnit: AVAudioUnit?
  private var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  private var viewController: ViewController?
  private let playEngine: SimplePlayEngine
  private let componentDescription: AudioComponentDescription
  private let searchCriteria: AudioComponentDescription
  private var creationError: AudioUnitLoaderError? { didSet { notifyDelegate() } }
  private var remainingLocateAttempts: Int
  private let delayBeforeNextLocateAttempt: Double
  private var notificationRegistration: NSObjectProtocol?
  private var hasUpdates = false

  public let lastState = UserDefaults.standard.dictionary(forKey: lastStateKey)
  public var isPlaying: Bool { playEngine.isPlaying }

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
  public init(name: String, componentDescription: AudioComponentDescription, loop: SampleLoop,
              delayBeforeNextLocateAttempt: Double = 0.2, maxLocateAttempts: Int = 50) {
    self.log = .init(subsystem: name, category: "AudioUnitLoader")
    self.delayBeforeNextLocateAttempt = delayBeforeNextLocateAttempt
    self.remainingLocateAttempts = maxLocateAttempts
    self.playEngine = .init(name: name, audioFileName: loop.rawValue)
    self.componentDescription = componentDescription
    self.searchCriteria = AudioComponentDescription(componentType: componentDescription.componentType,
                                                    componentSubType: 0,
                                                    componentManufacturer: 0,
                                                    componentFlags: 0,
                                                    componentFlagsMask: 0)
    super.init()

    let name = AVAudioUnitComponentManager.registrationsChangedNotification
    notificationRegistration = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { _ in
      self.hasUpdates = true
    }

    self.locate()
  }

  /**
   Use AVAudioUnitComponentManager to locate the AUv3 component we want. This is done asynchronously in the background.
   If the component we want is not found, start listening for notifications from the AVAudioUnitComponentManager for
   updates and try again.
   */
  private func locate() {
    let components = AVAudioUnitComponentManager.shared().components(matching: searchCriteria)

    for (_, each) in components.enumerated() {
      if each.audioComponentDescription.componentManufacturer == self.componentDescription.componentManufacturer,
         each.audioComponentDescription.componentType == self.componentDescription.componentType,
         each.audioComponentDescription.componentSubType == self.componentDescription.componentSubType {
        DispatchQueue.main.async {
          self.createAudioUnit(each.audioComponentDescription)
        }
        return
      }
    }

    scheduleCheck()
  }

  private func scheduleCheck() {
    remainingLocateAttempts -= 1
    if remainingLocateAttempts <= 0 {
      creationError = .componentNotFound
      return
    }

    Timer.scheduledTimer(withTimeInterval: delayBeforeNextLocateAttempt, repeats: false) { _ in
      if self.hasUpdates {
        self.hasUpdates = false
        self.locate()
      } else {
        self.scheduleCheck()
      }
    }
  }

  /**
   Create the desired component using the AUv3 API
   */
  private func createAudioUnit(_ componentDescription: AudioComponentDescription) {
    precondition(avAudioUnit == nil)

#if os(macOS)
    let options: AudioComponentInstantiationOptions = .loadInProcess
#else
    let options: AudioComponentInstantiationOptions = .loadOutOfProcess
#endif

    AVAudioUnit.instantiate(with: componentDescription, options: options) { [weak self] avAudioUnit, error in
      guard let self = self else { return }
      if let error = error {
        self.creationError = .framework(error: error)
        return
      }

      guard let avAudioUnit = avAudioUnit else {
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
    avAudioUnit.auAudioUnit.requestViewController { [weak self] controller in
      guard let self = self else { return }
      guard let controller = controller else {
        self.creationError = AudioUnitLoaderError.nilViewController
        return
      }
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

    let maximumFramesToRender = playEngine.maximumFramesToRender
    avAudioUnit.auAudioUnit.maximumFramesToRender = maximumFramesToRender

    notifyDelegate()
  }

  private func notifyDelegate() {
    if let creationError = creationError {
      DispatchQueue.main.async { self.delegate?.failed(error: creationError) }
    } else if let avAudioUnit = avAudioUnit, let viewController = viewController {
      DispatchQueue.main.async { self.delegate?.connected(audioUnit: avAudioUnit, viewController: viewController) }
    }
  }
}

public extension AudioUnitLoader {

  /**
   Save the current state of the AUv3 component to UserDefaults for future restoration. Saves the value from
   the audio unit's `fullState` property.
   */
  func save() {
    guard let audioUnit = auAudioUnit else { return }
    if let lastState = audioUnit.fullState {
      UserDefaults.standard.set(lastState, forKey: Self.lastStateKey)
    } else {
      UserDefaults.standard.removeObject(forKey: Self.lastStateKey)
    }
  }

  /**
   Restore the state of the AUv3 component using values found in UserDefaults.
   */
  func restore() {
    guard let audioUnit = auAudioUnit else { return }
    if let lastState = lastState {
      audioUnit.fullState = lastState
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
