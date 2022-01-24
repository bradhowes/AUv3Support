// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

// import AUv3Support
import AVKit
import UIKit
import os.log

public struct HostViewConfig {
  let name: String
  let version: String
  let appStoreId: String
  let componentDescription: AudioComponentDescription
  let sampleLoop: AudioUnitLoader.SampleLoop
  let appStoreVisitor: (URL) -> Void

  public init(name: String, version: String, appStoreId: String, componentDescription: AudioComponentDescription,
              sampleLoop: AudioUnitLoader.SampleLoop, appStoreVisitor: @escaping (URL) -> Void) {
    self.name = name
    self.version = version
    self.appStoreId = appStoreId
    self.componentDescription = componentDescription
    self.sampleLoop = sampleLoop
    self.appStoreVisitor = appStoreVisitor
  }
}

public final class HostUIViewController: UIViewController {
  private var log: OSLog!

  public var config: HostViewConfig?

  private let showedInitialAlert = "showedInitialAlert"

  private var audioUnitLoader: AudioUnitLoader!
  public var userPresetsManager: UserPresetsManager?

  public var avAudioUnit: AVAudioUnit?
  public var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  public var audioUnitViewController: UIViewController?

  @IBOutlet public var playButton: UIButton!
  @IBOutlet public var bypassButton: UIButton!
  @IBOutlet public var reviewButton: UIButton!
  @IBOutlet public var presetSelection: UISegmentedControl!
  @IBOutlet public var userPresetsMenuButton: UIButton!
  @IBOutlet weak var presetName: UILabel!

  @IBOutlet public var containerView: UIView!

  @IBOutlet public weak var instructions: UIView!
  @IBOutlet public weak var instructionsLabel: UILabel!


  private lazy var renameAction = UIAction(title: "Rename",
                                           handler: RenamePresetAction(self, completion: updatePresetMenu).start(_:))
  private lazy var deleteAction = UIAction(title: "Delete",
                                           handler: DeletePresetAction(self, completion: updatePresetMenu).start(_:))
  private lazy var saveAction = UIAction(title: "Save",
                                         handler: SavePresetAction(self, completion: updatePresetMenu).start(_:))

  private var allParameterValuesObserverToken: NSKeyValueObservation?
  private var parameterTreeObserverToken: AUParameterObserverToken?
}

// MARK: - View Management

extension HostUIViewController {

  public func setConfig(_ config: HostViewConfig) {
    log = .init(subsystem: config.name, category: "HostUIViewController")
    self.config = config
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    guard let config = self.config else { fatalError() }

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
    instructions.layer.borderColor = UIColor.systemOrange.cgColor
    instructions.layer.cornerRadius = 16

    instructions.isHidden = true

    reviewButton.setTitle(config.version, for: .normal)
    instructionsLabel.text =
          """
The AUv3 component '\(config.name)' is now available on your device and can be used in other AUv3 host apps such as \
GarageBand and AUM.

You can continue to use this app to experiment, but you do not need to have it running in order to access the AUv3 \
component in other apps.

If you delete this app from your device, the AUv3 component will no longer be available for use in other host \
applications.
"""

    audioUnitLoader = .init(name: config.name, componentDescription: config.componentDescription,
                            loop: config.sampleLoop)
    audioUnitLoader.delegate = self

    let alwaysShow = true
    if UserDefaults.standard.bool(forKey: showedInitialAlert) == false || alwaysShow {
      instructions.isHidden = false
    }
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    playButton.setImage(UIImage(named: "stop"), for: [.highlighted, .selected])
    bypassButton.setImage(UIImage(named: "bypassed"), for: [.highlighted, .selected])
  }

  public func stopPlaying() {
    playButton.isSelected = false
    playButton.isEnabled = false
    bypassButton.isEnabled = false
    bypassButton.isSelected = false
    audioUnitLoader.cleanup()
  }
}

// MARK: - Actions

extension HostUIViewController {

  @IBAction public func togglePlay(_ sender: UIButton) {
    let isPlaying = audioUnitLoader.togglePlayback()
    bypassButton.isEnabled = isPlaying
    playButton.isSelected = isPlaying
    playButton.tintColor = isPlaying ? .systemYellow : .systemTeal

    if !isPlaying {
      bypassButton.isSelected = false
    }
  }

  @IBAction public func toggleBypass(_ sender: UIButton) {
    let wasBypassed = auAudioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    auAudioUnit?.shouldBypassEffect = isBypassed
    sender.isSelected = isBypassed
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
    presetName.text = auAudioUnit?.factoryPresetsNonNil[presetSelection.selectedSegmentIndex].name
  }

  @IBAction public func dismissInstructions(_ sender: Any) {
    instructions.isHidden = true
    UserDefaults.standard.set(true, forKey: showedInitialAlert)
  }
}

// MARK: - AudioUnitHostDelegate

extension HostUIViewController: AudioUnitLoaderDelegate {

  public func connected(audioUnit: AVAudioUnit, viewController: UIViewController) {
    userPresetsManager = .init(for: audioUnit.auAudioUnit)
    avAudioUnit = audioUnit
    audioUnitViewController = viewController
    connectFilterView(audioUnit, viewController)
    connectParametersToControls(audioUnit.auAudioUnit)
  }

  public func failed(error: AudioUnitLoaderError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    let controller = UIAlertController(title: "AUv3 Failure", message: message, preferredStyle: .alert)
    present(controller, animated: true)
  }
}

// MARK: - Private

extension HostUIViewController {

  public func showInstructions() {
#if !Dev
    if UserDefaults.standard.bool(forKey: showedInitialAlert) {
      instructions.isHidden = true
      return
    }
#endif
    instructions.isHidden = false

    // Since this is the first time to run, apply the first factory preset.
    userPresetsManager?.makeCurrentPreset(number: 0)
  }

  public func connectFilterView(_ audioUnit: AVAudioUnit, _ viewController: UIViewController) {
    containerView.addSubview(viewController.view)
    viewController.view.pinToSuperviewEdges()

    addChild(viewController)
    view.setNeedsLayout()
    containerView.setNeedsLayout()

    playButton.isEnabled = true
    presetSelection.isEnabled = true
    userPresetsMenuButton.isEnabled = true

    let presetCount = auAudioUnit?.factoryPresetsNonNil.count ?? 0
    while presetSelection.numberOfSegments < presetCount {
      let index = presetSelection.numberOfSegments + 1
      presetSelection.insertSegment(withTitle: "\(index)", at: index - 1, animated: false)
    }
    while presetSelection.numberOfSegments > presetCount {
      presetSelection.removeSegment(at: presetSelection.numberOfSegments - 1, animated: false)
    }

    presetSelection.selectedSegmentIndex = 0
    useFactoryPreset(nil)
  }

  public func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    guard let parameterTree = audioUnit.parameterTree else {
      fatalError("FilterAudioUnit does not define any parameters.")
    }

    audioUnitLoader.restore()
    updatePresetMenu()

    allParameterValuesObserverToken = audioUnit.observe(\.allParameterValues) { [weak self] _, _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "allParameterValues changed")
      DispatchQueue.main.async { self.updateView() }
    }

    parameterTreeObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "MainViewController - parameterTree changed - %d", address)
      DispatchQueue.main.async { self.updateView() }
    })
  }

  public func usePreset(number: Int) {
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }

  func updatePresetMenu() {
    os_log(.debug, log: log, "updatePresetMenu BEGIN")
    guard let userPresetsManager = userPresetsManager else {
      os_log(.debug, log: log, "updatePresetMenu END - nil userPresetsManager")
      return
    }

    let active = userPresetsManager.audioUnit.currentPreset?.number ?? Int.max

    let factoryPresets = userPresetsManager.audioUnit.factoryPresetsNonNil.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    os_log(.debug, log: log, "updatePresetMenu - adding %d factory presets", factoryPresets.count)
    let factoryPresetsMenu = UIMenu(title: "Factory", options: .displayInline, children: factoryPresets)

    let userPresets = userPresetsManager.presetsOrderedByName.map { (preset: AUAudioUnitPreset) -> UIAction in
      let action = UIAction(title: preset.name, handler: { _ in self.usePreset(number: preset.number) })
      action.state = active == preset.number ? .on : .off
      return action
    }

    os_log(.debug, log: log, "updatePresetMenu - adding %d user presets", userPresets.count)

    let userPresetsMenu = UIMenu(title: "User", options: .displayInline, children: userPresets)

    let actionsGroup = UIMenu(title: "Actions", options: .displayInline,
                              children: active < 0 ? [saveAction, renameAction, deleteAction] : [saveAction])

    let menu = UIMenu(title: "Presets", options: [], children: [userPresetsMenu, factoryPresetsMenu, actionsGroup])

    if #available(iOS 14, *) {
      userPresetsMenuButton.menu = menu
      userPresetsMenuButton.showsMenuAsPrimaryAction = true
    }

    os_log(.debug, log: log, "updatePresetMenu END")
  }

  private func updateView() {
    guard let auAudioUnit = auAudioUnit else { return }
    updatePresetMenu()
    updatePresetSelection(auAudioUnit)
    audioUnitLoader.save()
  }

  private func updatePresetSelection(_ auAudioUnit: AUAudioUnit) {
    if let presetNumber = auAudioUnit.currentPreset?.number {
      os_log(.info, log: log, "updatePresetSelection: %d", presetNumber)
      presetSelection.selectedSegmentIndex = presetNumber
    } else {
      presetSelection.selectedSegmentIndex = -1
    }
  }
}

// MARK: - Alerts and Prompts

extension HostUIViewController {

  public func notify(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default))
    present(controller, animated: true)
  }

  public func yesOrNo(title: String, message: String, continuation: @escaping (UIAlertAction) -> Void) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(.init(title: "Continue", style: .default, handler: continuation))
    controller.addAction(.init(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }
}

#endif
