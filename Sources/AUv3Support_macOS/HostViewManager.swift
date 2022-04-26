// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)

import AUv3Support
import CoreAudioKit
import Cocoa
import AVFAudio
import os.log

public final class HostViewManager: NSObject {
  private let log = Shared.logger("HostViewManager")
  private let config: HostViewConfig
  private let audioUnitLoader: AudioUnitLoader
  private var restored = false

  private var userPresetsManager: UserPresetsManager?
  private var presetsMenuManager: PresetsMenuManager?

  private var avAudioUnit: AVAudioUnit?
  private var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  private var audioUnitViewController: NSViewController?

  private var currentPresetObserverToken: NSKeyValueObservation?
  private var userPresetsObserverToken: NSKeyValueObservation?

  public static let showedInitialAlertKey = "showedInitialAlert"

  private var showingInitialPrompt = false

  public static var alwaysShowInstructions: Bool = false

  public static var showInstructions: Bool {
    let firstTime = (UserDefaults.standard.bool(forKey: showedInitialAlertKey) == false) || alwaysShowInstructions
    let takingSnapshots = CommandLine.arguments.first { $0 == "snaps" } != nil
    return firstTime && !takingSnapshots
  }

  public init(config: HostViewConfig) {
    self.config = config
    self.audioUnitLoader = .init(name: config.componentName, componentDescription: config.componentDescription,
                                 loop: config.sampleLoop)
    super.init()

    config.playButton.target = self
    config.playButton.isEnabled = false

    config.bypassButton.target = self
    config.bypassButton.isEnabled = false

    config.playMenuItem.target = self
    config.playMenuItem.isEnabled = false

    config.bypassMenuItem.target = self
    config.bypassMenuItem.isEnabled = false

    self.audioUnitLoader.delegate = self

    NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil,
                                           queue: nil) { _ in
      self.audioUnitLoader.save()
    }
  }
}

extension HostViewManager {

  public func showInitialPrompt() {
    guard Self.showInstructions else { return }

    disablePlaying()
    showingInitialPrompt = true

    UserDefaults.standard.set(true, forKey: Self.showedInitialAlertKey)
    let alert = NSAlert()
    alert.alertStyle = .informational
    alert.messageText = "AUv3 Component Installed"
    alert.informativeText =
      """
The AUv3 component '\(config.componentName)' is now available on your device and can be used in other AUv3 host apps \
such as GarageBand and Logic.

You can continue to use this app to experiment, but you do not need to have it running in order to access the AUv3 \
component in other apps.

If you delete this app from your device, the AUv3 component will no longer be available for use in other host \
applications.
"""
    alert.addButton(withTitle: "OK")
    alert.beginSheetModal(for: config.viewController.view.window!){ _ in
      DispatchQueue.main.async {
        self.showingInitialPrompt = false
        self.enablePlaying()
      }
    }
  }
}

extension HostViewManager: AudioUnitLoaderDelegate {

  public func connected(audioUnit: AVAudioUnit, viewController: NSViewController) {
    let userPresetsManager = UserPresetsManager(for: audioUnit.auAudioUnit)
    self.userPresetsManager = userPresetsManager

    let presetsMenuManager = PresetsMenuManager(button: config.presetsButton, appMenu: config.presetsMenu,
                                                userPresetsManager: userPresetsManager)
    self.presetsMenuManager = presetsMenuManager
    presetsMenuManager.build()

    avAudioUnit = audioUnit
    audioUnitViewController = viewController
    connectFilterView(audioUnit, viewController)

    updateView()
  }

  public func failed(error: AudioUnitLoaderError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    notify(title: "AUv3 Failure", message: message)
  }
}

extension HostViewManager {

  @IBAction private func togglePlay(_ sender: NSButton) {
    audioUnitLoader.togglePlayback()
    let isPlaying = audioUnitLoader.isPlaying
    config.playButton.state = isPlaying ? .on : .off
    config.playMenuItem.title = isPlaying ? "Stop" : "Play"

    config.bypassButton.isEnabled = isPlaying
    config.bypassMenuItem.isEnabled = isPlaying

    if !isPlaying && auAudioUnit?.shouldBypassEffect ?? false {
      toggleBypass(config.bypassButton)
    }
  }

  @IBAction private func toggleBypass(_ sender: NSButton) {
    let wasBypassed = auAudioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    auAudioUnit?.shouldBypassEffect = isBypassed
    config.bypassButton.state = isBypassed ? .on : .off
    config.bypassMenuItem.title = isBypassed ? "Resume" : "Bypass"
  }
}

extension HostViewManager: NSWindowDelegate {

  public func windowWillClose(_ notification: Notification) {
    audioUnitLoader.cleanup()
  }
}

extension HostViewManager {

  private func enablePlaying() {
    if userPresetsManager != nil && !showingInitialPrompt {
      config.playButton.isEnabled = true
      config.playMenuItem.isEnabled = true
    }
  }

  private func disablePlaying() {
    config.playButton.isEnabled = false
    config.playMenuItem.isEnabled = false
  }

  private func connectFilterView(_ audioUnit: AVAudioUnit, _ viewController: NSViewController) {
    config.containerView.addSubview(viewController.view)
    viewController.view.pinToSuperviewEdges()

    config.viewController.addChild(viewController)
    config.viewController.view.needsLayout = true
    config.containerView.needsLayout = true

    enablePlaying()

    connectParametersToControls(audioUnit.auAudioUnit)
  }

  private func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    currentPresetObserverToken = audioUnit.observe(\.currentPreset) { _, _ in
      DispatchQueue.main.async { self.updateView() }
    }

    userPresetsObserverToken = audioUnit.observe(\.userPresets) { _, _ in
      DispatchQueue.main.async { self.presetsMenuManager?.build() }
    }
  }

  private func showPresetName() {
    guard let window = config.viewController.view.window else { return }
    if let presetName = userPresetsManager?.currentPreset?.name {
      if #available(macOS 11, *) {
        window.subtitle = presetName
      } else {
        window.title = "\(config.componentName) - \(presetName)"
      }
    } else {
      if #available(macOS 11, *) {
        window.subtitle = ""
      } else {
        window.title = config.componentName
      }
    }
  }

  private func updateView() {
    presetsMenuManager?.selectActive()
    showPresetName()

    if !restored {
      restored = true
      audioUnitLoader.restore()
    } else {
      audioUnitLoader.save()
    }
  }
}

// MARK: - Alerts and Prompts

extension HostViewManager {

  public func notify(title: String, message: String) {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.informativeText = title
    alert.messageText = message
    alert.addButton(withTitle: "OK")
    alert.beginSheetModal(for: config.viewController.view.window!){ _ in }
  }
}

#endif
