// Copyright © 2022 Brad Howes. All rights reserved.

#if os(macOS)

import CoreAudioKit
import AUv3Support
import AppKit

public struct HostViewConfig {
  let componentName: String
  let componentVersion: String
  let componentDescription: AudioComponentDescription
  let sampleLoop: AudioUnitLoader.SampleLoop

  let playButton: NSButton
  let bypassButton: NSButton
  let presetsButton: NSPopUpButton

  let playMenuItem: NSMenuItem
  let bypassMenuItem: NSMenuItem
  let presetsMenu: NSMenu

  let alwaysShowNotice: Bool
  let defaults: UserDefaults

  var versionTag: String {
    componentVersion.first == "v" ? componentVersion : "v\(componentVersion)"
  }

  weak var viewController: NSViewController!
  weak var containerView: NSView!

  public init(
    componentName: String,
    componentVersion: String,
    componentDescription: AudioComponentDescription,
    sampleLoop: AudioUnitLoader.SampleLoop,
    playButton: NSButton,
    bypassButton: NSButton,
    presetsButton: NSPopUpButton,
    playMenuItem: NSMenuItem,
    bypassMenuItem: NSMenuItem,
    presetsMenu: NSMenu,
    viewController: NSViewController,
    containerView: NSView,
    alwaysShowNotice: Bool = false,
    defaults: UserDefaults = .standard
  ) {
    self.componentName = componentName
    self.componentVersion = componentVersion
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.playButton = playButton
    self.bypassButton = bypassButton
    self.presetsButton = presetsButton
    self.playMenuItem = playMenuItem
    self.bypassMenuItem = bypassMenuItem
    self.presetsMenu = presetsMenu
    self.viewController = viewController
    self.containerView = containerView
    self.alwaysShowNotice = alwaysShowNotice
    self.defaults = defaults
  }
}

#endif
