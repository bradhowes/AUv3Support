// Copyright © 2022 Brad Howes. All rights reserved.

import AVFoundation
import os.log

/**
 Wrapper around AVAudioEngine that manages its wiring with an AVAudioUnit instance.
 */
public final class SimplePlayEngine {
  static let bundle = Bundle(for: SimplePlayEngine.self)
  static let bundleIdentifier = bundle.bundleIdentifier!

  private let log: OSLog
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var activeEffect: AVAudioUnit?
  private let file: AVAudioFile

  private lazy var stateChangeQueue = DispatchQueue(label: Self.bundleIdentifier + ".StateChangeQueue")

  /// True if engine is currently playing the audio file.
  public var isPlaying: Bool { player.isPlaying }

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
   Create new audio processing setup, with an audio file player connected directly to the mixer for the main
   output device.
   */
  public init(name: String, audioFileName: String) {
    self.log = .init(subsystem: name, category: "SimplePlayEngine")
    self.file = Self.audioFileResource(name: audioFileName)
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
  }
}

extension SimplePlayEngine {

  /**
   Start playback of the audio file player.
   */
  public func start() {
    os_log(.debug, log: log, "start BEGIN")
    stateChangeQueue.sync {
      guard !player.isPlaying else { return }
      updateAudioSession(active: true)
      beginLoop()
      do {
        os_log(.debug, log: log, "start - starting engine")
        try engine.start()
      } catch {
        fatalError("failed to start AVAudioEngine")
      }
      os_log(.debug, log: log, "start - starting player")
      player.play()
    }
    os_log(.debug, log: log, "start END")
  }

  /**
   Stop playback of the audio file player.
   */
  public func stop() {
    os_log(.debug, log: log, "stop BEGIN")
    stateChangeQueue.sync {
      guard player.isPlaying else { return }
      os_log(.debug, log: log, "stop - stopping player")
      player.stop()
      os_log(.debug, log: log, "stop - stopping engine")
      engine.stop()
      updateAudioSession(active: false)
    }
    os_log(.debug, log: log, "stop END")
  }

  /**
   Toggle the playback of the audio file player.

   @returns state of the player
   */
  public func startStop() -> Bool {
    if player.isPlaying { stop() } else { start() }
    return player.isPlaying
  }

  /**
   Install an effect AudioUnit between an audio source and the main output mixer. If there was a previous effect
   installed it is removed from the signal chain. If the sound resource was playing it will be resumed after the
   new effect is installed.

   @param audioUnit the audio unit to install
   @param completion closure to call when finished
   */
  public func connectEffect(audioUnit: AVAudioUnit, completion: @escaping (() -> Void) = {}) {
    os_log(.debug, log: log, "connectEffect BEGIN")
    defer { completion() }
    pauseWhile {
      disconnectEffect()
      activeEffect = audioUnit
      os_log(.debug, log: log, "connectEffect - attaching effect")
      engine.attach(audioUnit)
      os_log(.debug, log: log, "connectEffect - connecting player to effect - format: %{public}s",
             file.processingFormat.description)
      engine.connect(player, to: audioUnit, format: nil)
      os_log(.debug, log: log, "connectEffect - connecting effect to mixer")
      // engine.connect(audioUnit, to: engine.mainMixerNode, format: file.processingFormat)
      engine.connect(audioUnit, to: engine.mainMixerNode, format: nil)
    }
    os_log(.debug, log: log, "connectEffect END")
  }

  /**
   Uninstall a previously-installed effect AudioUnit.
   */
  public func disconnectEffect() {
    os_log(.debug, log: log, "disconnectEffect BEGIN")
    guard let previous = activeEffect else { return }
    activeEffect = nil
    pauseWhile {
      os_log(.debug, log: log, "disconnectEffect - disconnecting effect")
      engine.disconnectNodeInput(previous)
      engine.disconnectNodeInput(engine.mainMixerNode)
      os_log(.debug, log: log, "disconnectEffect - detaching effect")
      engine.detach(previous)
      os_log(.debug, log: log, "disconnectEffect - connecting player to mixer")
      engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
    }
    os_log(.debug, log: log, "disconnectEffect END")
  }
}

private extension SimplePlayEngine {

  /**
   If player is currently playing audio pause it the execution of the given block and then resume it after the block
   is done.

   - parameter block: closure to execute while player is paused
   */
  private func pauseWhile(_ block: () -> Void) {
    let wasPlaying = player.isPlaying
    if wasPlaying { player.pause() }
    block()
    if wasPlaying { player.play() }
  }

  private func updateAudioSession(active: Bool) {
    #if os(iOS)
    os_log(.debug, log: log, "updateAudioSession BEGIN - active: %d", active)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default)
      try session.setActive(active)
    } catch {
      fatalError("Could not set Audio Session active \(active). error: \(error).")
    }
    os_log(.debug, log: log, "updateAudioSession END")
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
