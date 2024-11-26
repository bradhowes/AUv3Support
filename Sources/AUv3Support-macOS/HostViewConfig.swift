// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(macOS)

import CoreAudioKit
import AUv3Support
import AppKit

@MainActor
public struct HostViewConfig {
  let componentName: String
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

  weak var viewController: NSViewController!
  weak var containerView: NSView!

  @available(*, deprecated, message: "Version is no longer needed")
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

  public init(
    componentName: String,
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
