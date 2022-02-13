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
   Create new audio processing setup, with an audio file player for a signal source.
   */
  public init(name: String, audioFileName: String) {
    self.log = .init(subsystem: name, category: "SimplePlayEngine")
    self.file = Self.audioFileResource(name: audioFileName)
    engine.attach(player)
  }
}

extension SimplePlayEngine {

  /**
   Install an effect AudioUnit between an audio source and the main output mixer.

   @param audioUnit the audio unit to install
   @param completion closure to call when finished
   */
  public func connectEffect(audioUnit: AVAudioUnit, completion: @escaping (() -> Void) = {}) {
    os_log(.debug, log: log, "connectEffect BEGIN")
    defer { completion() }
    os_log(.debug, log: log, "connectEffect - attaching effect")
    engine.attach(audioUnit)
    os_log(.debug, log: log, "connectEffect - player -> effect")
    engine.connect(player, to: audioUnit, format: file.processingFormat)
    os_log(.debug, log: log, "connectEffect - effect -> mixer (speaker)")
    engine.connect(audioUnit, to: engine.mainMixerNode, format: file.processingFormat)
    os_log(.debug, log: log, "connectEffect END")
  }

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
}

private extension SimplePlayEngine {

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
