// Copyright © 2022-2024 Brad Howes. All rights reserved.

import AVFoundation

/**
 The loops that are available.
 */
public enum SampleLoop: String {
  case sample1 = "sample1.wav"
  case sample2 = "sample2.caf"
}

/**
 Wrapper around AVAudioEngine that manages its wiring with an AVAudioUnit instance.
 */
public final class SimplePlayEngine: @unchecked Sendable {

  static let bundle = Bundle(for: SimplePlayEngine.self)
  static let bundleIdentifier = bundle.bundleIdentifier ?? "unknown"

  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var activeEffect: AVAudioUnit?
  private let file: AVAudioFile
  private let stateChangeQueue = DispatchQueue(label: "SimplePlayEngine")

  /// True if engine is currently playing the audio file.
  public var isPlaying: Bool { stateChangeQueue.sync { player.isPlaying } }
  public var maximumFramesToRender: AUAudioFrameCount { engine.mainMixerNode.auAudioUnit.maximumFramesToRender }

  static func audioFileResource(name: String) -> AVAudioFile {
    let parts = name.split(separator: .init("."))
    let filename = String(parts[0])
    let ext = String(parts[1])

    let bundles = Bundle.allBundles + [Bundle.module]
    for bundle in bundles {
      if let url = bundle.url(forResource: filename, withExtension: ext) {
        return try! AVAudioFile(forReading: url)
      }
    }

    fatalError("\(filename).\(ext) missing from bundle")
  }

  /**
   Create new audio processing setup, with an audio file player for a signal source.
   - parameter audioFileName: the name of the audio resource to play
   */
  public init(sampleLoop: SampleLoop) {
    print("new SimplePlayEngine")
    self.file = Self.audioFileResource(name: sampleLoop.rawValue)
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
  }
}

extension SimplePlayEngine {

  /**
   Install an effect AudioUnit between an audio source and the main output mixer.

   - parameter audioUnit: the audio unit to install
   - parameter completion: closure to call when finished
   */
  public func connectEffect(audioUnit: AVAudioUnit, completion: @escaping (() -> Void) = {}) {
    defer { completion() }

    audioUnit.auAudioUnit.maximumFramesToRender = maximumFramesToRender
    activeEffect = audioUnit

    engine.disconnectNodeOutput(player)
    engine.attach(audioUnit)
    engine.connect(player, to: audioUnit, format: file.processingFormat)
    engine.connect(audioUnit, to: engine.mainMixerNode, format: file.processingFormat)
    do {
      try engine.start()
    } catch {
      fatalError("failed to start AVAudioEngine")
    }
  }

  /**
   Start playback of the audio file player.
   */
  public func start() {
    stateChangeQueue.sync {
      print("starting SimplePlayEngine")
      self.startPlaying()
    }
  }

  /**
   Stop playback of the audio file player.
   */
  public func stop() {
    stateChangeQueue.sync {
      print("stopping SimplePlayEngine")
      self.stopPlaying()
    }
  }

  /**
   Toggle the playback of the audio file player.

   - returns: state of the player
   */
  public func startStop() -> Bool {
    if isPlaying {
      stop()
    } else {
      start()
    }
    return isPlaying
  }

  public func setBypass(_ bypass: Bool) {
    activeEffect?.auAudioUnit.shouldBypassEffect = bypass
  }
}

extension SimplePlayEngine {

  private func startPlaying() {
    updateAudioSession(active: true)

    do {
      try engine.start()
    } catch {
      stopPlaying()
      fatalError("Could not start engine - error: \(error).")
    }

    beginLoop()
    player.play()
  }

  private func stopPlaying() {
    player.stop()
    engine.stop()
    updateAudioSession(active: false)
  }
}

extension SimplePlayEngine {

  private func updateAudioSession(active: Bool) {
    #if os(iOS)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default)
      try session.setActive(active)
    } catch {
      fatalError("Could not set Audio Session active \(active). error: \(error).")
    }
    #endif
  }

  /**
   Start playing the audio resource and play it again once it is done.
   */
  private func beginLoop() {
    player.scheduleFile(file, at: nil) {
      self.stateChangeQueue.async {
        if self.player.isPlaying {
          self.beginLoop()
        }
      }
    }
  }
}
