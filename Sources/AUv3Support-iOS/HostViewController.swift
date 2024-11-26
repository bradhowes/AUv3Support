// Copyright © 2022-2024 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import AVKit
import UIKit
import os.log

extension Shared {

  /// Access the storyboard that defines the HostUIView for the AUv3 host app
  @MainActor
  public static let hostViewStoryboard = Storyboard(name: "HostView", bundle: .module)

  /**
   Instantiate a new HostUIView and embed it into the view of the given view controller.

   - parameter parent: the view controller to embed in
   - parameter config: the configuration to use
   - returns: the HostUIViewController of the view that was embedded
   */
  @MainActor
  public static func embedHostView(into parent: ViewController, config: HostViewConfig) -> HostViewController {

    let hostViewController = hostViewStoryboard.instantiateInitialViewController() as! HostViewController
    hostViewController.setConfig(config)

    parent.view.addSubview(hostViewController.view)
    hostViewController.view.pinToSuperviewEdges()

    parent.addChild(hostViewController)
    parent.view.setNeedsLayout()

    return hostViewController
  }
}

/**
 A basic AudioUnit host that is used to showcase a specific audio unit. It handles locating the audio unit, wiring it up
 to process audio, and it has controls for selecting and managing presets. All bits that are specific to a particular
 AudioUnit are specified in the `HostViewConfig` struct.
 */
@MainActor
public final class HostViewController: UIViewController {
  private var log: OSLog!

  public static let showedInitialAlertKey = "showedInitialAlertVersion"

  public var showInstructions: Bool {
    let versionTag = Bundle.main.versionTag
    let lastVersion = config!.defaults.string(forKey: HostViewController.showedInitialAlertKey) ?? ""
    config!.defaults.set(versionTag, forKey: Self.showedInitialAlertKey)
    let firstTime = config!.alwaysShowNotice || (lastVersion != versionTag && ("v" + lastVersion) != versionTag)
    let takingSnapshots = CommandLine.arguments.first { $0 == "snaps" } != nil
    return firstTime && !takingSnapshots
  }

  public var config: HostViewConfig?
  public var userPresetsManager: UserPresetsManager?

  public var avAudioUnit: AVAudioUnit?
  public var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  public var audioUnitViewController: UIViewController?

  private var audioUnitLoader: AudioUnitLoader?
  private var restored = false

  @IBOutlet private var playButton: UIButton!
  @IBOutlet private var bypassButton: UIButton!
  @IBOutlet private var reviewButton: UIButton!
  @IBOutlet private var presetSelection: UISegmentedControl!
  @IBOutlet private var userPresetsMenuButton: UIButton!
  @IBOutlet private var presetName: UILabel!
  @IBOutlet private var containerView: UIView!
  @IBOutlet private var instructions: UIView!
  @IBOutlet private var instructionsLabel: UILabel!
  @IBOutlet private var instructionsOKButton: UIButton!

  private var currentPresetObserverToken: NSKeyValueObservation?
  private var userPresetsObserverToken: NSKeyValueObservation?
}

// MARK: - View Management

extension HostViewController {

  public func setConfig(_ config: HostViewConfig) {
    log = Shared.logger("HostViewController")
    self.config = config
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    guard let config = self.config else { fatalError() }
    let versionTag = Bundle.main.versionTag

    playButton.isEnabled = false
    bypassButton.isEnabled = false
    presetSelection.isEnabled = false
    userPresetsMenuButton.isEnabled = false
    userPresetsMenuButton.isHidden = true
    if #available(iOS 14, *) {
      userPresetsMenuButton.isHidden = false
      userPresetsMenuButton.showsMenuAsPrimaryAction = true
    }

    presetName.text = ""

    presetSelection.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    presetSelection.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)

    instructions.layer.borderWidth = 4
    instructions.layer.cornerRadius = 16

    instructions.isHidden = true

    reviewButton.setTitle(versionTag, for: .normal)

    instructionsLabel.text =
          """
The AUv3 component '\(config.name)' (\(versionTag)) is now available on your device and can be used in other \
AUv3 host apps such as GarageBand and AUM.

You can continue to use this app to experiment, but you do not need to have it running in order to access the AUv3 \
component in other apps.

If you delete this app from your device, the AUv3 component will no longer be available for use in other host \
applications.
"""

    audioUnitLoader = .init(name: config.name, componentDescription: config.componentDescription,
                            loop: config.sampleLoop)
    audioUnitLoader?.delegate = self

    applyTheme()

    instructions.isHidden = !showInstructions
    config.appDelegate.setResigningActiveBlock {
      self.saveState()
      self.stopPlaying()
    }
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    playButton.setImage(UIImage(named: "stop"), for: [.highlighted, .selected])
    bypassButton.setImage(UIImage(named: "bypassed"), for: [.highlighted, .selected])
  }

  public func saveState() {
    audioUnitLoader?.save()
  }

  public func stopPlaying() {
    playButton.isSelected = false
    playButton.isEnabled = auAudioUnit != nil
    bypassButton.isSelected = false
    bypassButton.isEnabled = auAudioUnit != nil
    presetSelection.isEnabled = auAudioUnit != nil

    audioUnitLoader?.save()
    audioUnitLoader?.cleanup()
  }
}

// MARK: - Actions

extension HostViewController {

  @IBAction public func togglePlay(_ sender: UIButton) {
    let isPlaying = audioUnitLoader?.togglePlayback() ?? false
    bypassButton.isEnabled = isPlaying
    playButton.isSelected = isPlaying

    setBypassState(false)
  }

  @IBAction public func toggleBypass(_ sender: UIButton) {
    let isBypassed = auAudioUnit?.shouldBypassEffect ?? false
    setBypassState(!isBypassed)
  }

  private func setBypassState(_ state: Bool) {
    bypassButton.isSelected = state
    auAudioUnit?.shouldBypassEffect = state
  }

  @IBAction public func visitAppStore(_ sender: UIButton) {
    guard let config = self.config else { return }
    guard let url = URL(string: "https://itunes.apple.com/app/id\(config.appStoreId)") else {
      fatalError("Expected a valid URL")
    }

    config.appStoreVisitor(url)
  }

  @IBAction public func useFactoryPreset(_ sender: UISegmentedControl? = nil) {
    userPresetsManager?.makeCurrentPreset(number: presetSelection.selectedSegmentIndex)
  }

  @IBAction public func dismissInstructions(_ sender: Any) {
    instructions.isHidden = true
  }
}

// MARK: - AudioUnitHostDelegate

extension HostViewController: AudioUnitLoaderDelegate {

  public func connected(audioUnit: AVAudioUnit, viewController: UIViewController) {
    userPresetsManager = .init(for: audioUnit.auAudioUnit)
    avAudioUnit = audioUnit
    audioUnitViewController = viewController
    connectFilterView(audioUnit, viewController)
    connectParametersToControls(audioUnit.auAudioUnit)
    updateView()
  }

  public func failed(error: AudioUnitLoaderError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    notify(title: "AUv3 Failure", message: message)
  }
}

// MARK: - ActionSupporter

extension HostViewController: ActionSupporter {

  public func askForName(title: String, placeholder: String, activity: String, _ closure: @escaping (String) -> Void) {
    let controller = UIAlertController(title: title, message: nil, preferredStyle: .alert)
    controller.addTextField { textField in textField.placeholder = placeholder }
    controller.addAction(UIAlertAction(title: activity, style: .default) { _ in
      guard let name = controller.textFields?.first?.text?.trimmingCharacters(in: .whitespaces), !name.isEmpty else {
        return
      }
      closure(name)
    })
    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }

  public func confirmAction(title: String, message: String, _ closure: @escaping () -> Void) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(.init(title: "Continue", style: .destructive, handler: { _ in closure() }))
    controller.addAction(.init(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }

  public func notifyFailure(title: String, message: String) {
    notify(title: title, message: message)
  }

  public func completeAction() {
    self.updateView()
  }
}

// MARK: - Alerts and Prompts

extension HostViewController {

  public func notify(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default))
    present(controller, animated: true)
  }
}

// MARK: - Private

private extension HostViewController {

  func applyTheme() {
    guard let config = self.config else { fatalError() }
    let tintColor = config.tintColor

    playButton.tintColor = tintColor
    bypassButton.tintColor = tintColor
    userPresetsMenuButton.tintColor = tintColor
    presetName.textColor = tintColor
    presetSelection.selectedSegmentTintColor = tintColor

    instructions.layer.borderColor = tintColor.cgColor
    instructionsLabel.textColor = tintColor
    instructionsOKButton.setTitleColor(tintColor, for: .normal)

    reviewButton.setTitleColor(tintColor, for: .normal)
  }

  func connectFilterView(_ audioUnit: AVAudioUnit, _ viewController: UIViewController) {
    containerView.addSubview(viewController.view)
    viewController.view.pinToSuperviewEdges()

    addChild(viewController)
    view.setNeedsLayout()
    containerView.setNeedsLayout()

    playButton.isEnabled = true
    presetSelection.isEnabled = true
    userPresetsMenuButton.isEnabled = true

    setPresetSelectionControlSegmentSize(audioUnit.auAudioUnit.factoryPresetsNonNil.count)
  }

  func setPresetSelectionControlSegmentSize(_ presetCount: Int) {
    while presetSelection.numberOfSegments < presetCount {
      let index = presetSelection.numberOfSegments + 1
      presetSelection.insertSegment(withTitle: "\(index)", at: index - 1, animated: false)
    }
    while presetSelection.numberOfSegments > presetCount {
      presetSelection.removeSegment(at: presetSelection.numberOfSegments - 1, animated: false)
    }
  }

  func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    currentPresetObserverToken = audioUnit.observe(\.currentPreset) { _, _ in
      DispatchQueue.main.async { self.updateView() }
    }

    userPresetsObserverToken = audioUnit.observe(\.userPresets) { _, _ in
      DispatchQueue.main.async { self.updatePresetMenu() }
    }
  }

  func usePreset(number: Int) {
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }

  func updatePresetMenu() {
    guard let userPresetsManager = userPresetsManager else { return }

    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    let factoryPresets = userPresetsManager.audioUnit.factoryPresetsNonNil.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    let factoryPresetsMenu = UIMenu(title: "Factory", options: .displayInline, children: factoryPresets)
    let userPresets = userPresetsManager.presetsOrderedByName.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    let userPresetsMenu = UIMenu(title: "User", options: .displayInline, children: userPresets)

    var actions = [makeCreatePresetAction(presetsManager: userPresetsManager)]
    if active < 0 {
      actions.append(makeUpdatePresetAction(presetsManager: userPresetsManager))
      actions.append(makeRenamePresetAction(presetsManager: userPresetsManager))
      actions.append(makeDeletePresetAction(presetsManager: userPresetsManager))
    }

    let actionsGroup = UIMenu(title: "Actions", options: .displayInline, children: actions)
    let menu = UIMenu(title: "Presets", options: [], children: [userPresetsMenu, factoryPresetsMenu, actionsGroup])

    if #available(iOS 14, *) {
      userPresetsMenuButton.menu = menu
      userPresetsMenuButton.showsMenuAsPrimaryAction = true
    }
  }

  func updateView() {
    guard let audioUnitLoader = audioUnitLoader,
          let auAudioUnit = auAudioUnit else {
      return
    }

    updatePresetMenu()
    updatePresetSelection(auAudioUnit)

    if !restored {
      restored = true
      audioUnitLoader.restore()
    } else {
      audioUnitLoader.save()
    }
  }

  func updatePresetSelection(_ auAudioUnit: AUAudioUnit) {
    guard let preset = auAudioUnit.currentPreset else {
      presetName.text = ""
      presetSelection.selectedSegmentIndex = -1
      return
    }

    presetSelection.selectedSegmentIndex = preset.number >= 0 ? preset.number : -1
    presetName.text = preset.name
  }

  func makeCreatePresetAction(presetsManager: UserPresetsManager) -> UIAction {
    .init(title: "New", handler: CreatePreset(self, presetsManager: presetsManager).handler(_:))
  }

  func makeUpdatePresetAction(presetsManager: UserPresetsManager) -> UIAction {
    .init(title: "Update", handler: UpdatePreset(self, presetsManager: presetsManager).handler(_:))
  }

  func makeRenamePresetAction(presetsManager: UserPresetsManager) -> UIAction {
    .init(title: "Rename", handler: RenamePreset(self, presetsManager: presetsManager).handler(_:))
  }

  func makeDeletePresetAction(presetsManager: UserPresetsManager) -> UIAction {
    UIAction(title: "Delete", handler: DeletePreset(self, presetsManager: presetsManager).handler(_:))
  }
}

#endif
