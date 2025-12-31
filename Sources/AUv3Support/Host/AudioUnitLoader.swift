// Copyright © 2022-2024 Brad Howes. All rights reserved.

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
@MainActor
public protocol AudioUnitLoaderDelegate: AnyObject {
  /**
   Notification that the view controller in the AudioUnitHost has a wired AUAudioUnit
   */
  func connected(audioUnit: AVAudioUnit, viewController: AUv3ViewController)

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
public final class AudioUnitLoader: @unchecked Sendable {
  private static let lastStateKey = "lastStateKey"

  /// Delegate to signal when everything is wired up.
  private weak var delegate: AudioUnitLoaderDelegate?
  private var avAudioUnit: AVAudioUnit?
  private var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  private var viewController: AUv3ViewController?
  private let componentDescription: AudioComponentDescription
  private var creationError: AudioUnitLoaderError? { didSet { notifyDelegate() } }
  private var remainingLocateAttempts: Int
  private let delayBeforeNextLocateAttempt: Double
  private var notificationRegistration: NSObjectProtocol?

  public let lastState = UserDefaults.standard.dictionary(forKey: lastStateKey)
  private let log = Shared.logger("AudioUnitLoader")

  /**
   Create a new instance that will hopefully create a new AUAudioUnit and a view controller for its control view.

   - parameter componentDescription: the definition of the AUAudioUnit to create
   - parameter loop: the loop to play when the engine is playing
   */
  public init(
    componentDescription: AudioComponentDescription,
    delayBeforeNextLocateAttempt: Double = 0.2,
    maxLocateAttempts: Int = 50,
    delegate: AudioUnitLoaderDelegate? = nil
  ) {
    os_log(.info, log: log, "init - %{public}s", componentDescription.description)
    self.delayBeforeNextLocateAttempt = delayBeforeNextLocateAttempt
    self.remainingLocateAttempts = maxLocateAttempts
    self.componentDescription = componentDescription
    self.delegate = delegate

    DispatchQueue.global(qos: .background).async { [weak self] in
      self?.locate()
    }
  }

  /**
   Use AVAudioUnitComponentManager to locate the AUv3 component we want. This is done asynchronously in the background.
   If the component we want is not found, start listening for notifications from the AVAudioUnitComponentManager for
   updates and try again.
   */
  private func locate() {
    os_log(.info, log: log, "locate")
    let components = AVAudioUnitComponentManager.shared().components(matching: componentDescription)
    for (_, each) in components.enumerated() {
      os_log(.info, log: log, "found match - %{public}s", each.audioComponentDescription.description)
      DispatchQueue.global(qos: .background).async { [weak self] in
        self?.createAudioUnit(each.audioComponentDescription)
      }
      return
    }
    scheduleCheck()
  }

  private func scheduleCheck() {
    remainingLocateAttempts -= 1
    if remainingLocateAttempts <= 0 {
      os_log(.info, log: log, "scheduleCheck - no more attempts")
      creationError = .componentNotFound
      return
    }

    os_log(.info, log: log, "scheduleCheck - scheduling new check - %f", delayBeforeNextLocateAttempt)

    // Need to switch to main thread for Timer to work properly.
    DispatchQueue.main.async {
      Timer.scheduledTimer(withTimeInterval: self.delayBeforeNextLocateAttempt, repeats: false) { [weak self] _ in
        if let self {
          os_log(.info, log: log, "scheduleCheck - calling locate")
          self.locate();
        }
      }
    }
  }

  /**
   Create the desired component using the AUv3 API
   */
  private func createAudioUnit(_ componentDescription: AudioComponentDescription) {
    precondition(avAudioUnit == nil)
    os_log(.info, log: log, "createAudioUnit - %{public}s", componentDescription.description)

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

      DispatchQueue.main.async { [weak self] in
        self?.createViewController(avAudioUnit)
      }
    }
  }

  /**
   Create the component's view controller to embed in the host view.

   - parameter avAudioUnit: the AVAudioUnit that was instantiated
   */
  private func createViewController(_ avAudioUnit: AVAudioUnit) {
    os_log(.info, log: log, "createViewController")
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
  private func wireAudioUnit(_ avAudioUnit: AVAudioUnit, _ viewController: AUv3ViewController) {
    os_log(.info, log: log, "wireAudioUnit")
    self.avAudioUnit = avAudioUnit
    self.viewController = viewController
    notifyDelegate()
  }

  private func notifyDelegate() {
    os_log(.info, log: log, "notifyDelegate")
    if let creationError = creationError {
      os_log(.info, log: log, "notifyDelegate - failed: %{public}s", creationError.description)
      DispatchQueue.main.async { self.delegate?.failed(error: creationError) }
    } else if let avAudioUnit = avAudioUnit, let viewController = viewController {
      os_log(.info, log: log, "notifyDelegate - connected")
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

extension AVAudioUnitComponent: @retroactive @unchecked Sendable {}
extension AVAudioUnit: @retroactive @unchecked Sendable {}
