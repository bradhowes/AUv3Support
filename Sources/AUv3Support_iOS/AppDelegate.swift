// Copyright © 2022 Brad Howes. All rights reserved.

import UIKit
import AVKit
import os.log

open class AppDelegate: UIResponder, UIApplicationDelegate {
  private let log: OSLog
  private var stopPlayingBlock: (() -> Void)?
  public var window: UIWindow?

  public init(log: OSLog) {
    self.log = log
    super.init()
  }

  public func setStopPlayingBlock(_ block: @escaping () -> Void) {
    self.stopPlayingBlock = block
  }

  public func application(_ application: UIApplication,
                          didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
    } catch let error as NSError {
      fatalError("Failed to set the audio session category and mode: \(error.localizedDescription)")
    }
    let preferredSampleRate = 44100.0
    do {
      try audioSession.setPreferredSampleRate(preferredSampleRate)
    } catch let error as NSError {
      os_log(.error, log: log, "Failed to set the preferred sample rate: %{public}s",
             error.localizedDescription)
    }
    let preferredBufferSize = 512.0
    do {
      try audioSession.setPreferredIOBufferDuration(preferredBufferSize / preferredSampleRate)
    } catch let error as NSError {
      os_log(.error, log: log, "Failed to set the preferred IO buffer duration: %{public}s",
             error.localizedDescription)
    }
    return true
  }

  public func applicationWillResignActive(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillResignActive")
    stopPlayingBlock?()
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
    os_log(.info, log: log, "applicationDidEnterBackground")
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillEnterForeground")
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    os_log(.info, log: log, "applicationDidBecomeActive")
  }

  public func applicationWillTerminate(_ application: UIApplication) {
    os_log(.info, log: log, "applicationWillTerminate")
    stopPlayingBlock?()
  }
}
