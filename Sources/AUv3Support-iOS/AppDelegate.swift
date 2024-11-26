// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import UIKit
import AVKit
import os.log

open class AppDelegate: UIResponder, UIApplicationDelegate {
  private let log: OSLog
  private var resigningActiveBlock: (() -> Void)?
  public var window: UIWindow?

  override public init() {
    self.log = Shared.logger("AppDelegate")
    super.init()
  }

  public func setResigningActiveBlock(_ block: @escaping () -> Void) {
    self.resigningActiveBlock = block
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
    resigningActiveBlock?()
  }

  public func applicationDidEnterBackground(_ application: UIApplication) {
  }

  public func applicationWillEnterForeground(_ application: UIApplication) {
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
  }

  public func applicationWillTerminate(_ application: UIApplication) {
    resigningActiveBlock?()
  }
}

#endif
