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
    Shared.loggingSubsystem = config.name
    log = Shared.logger("HostUIViewController")
    self.config = config
  }

  override public func viewDidLoad() {
    os_log(.debug, log: log, "viewDidLoad BEGIN")
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

    let alwaysShow = false
    if UserDefaults.standard.bool(forKey: showedInitialAlert) == false || alwaysShow {
      instructions.isHidden = false
    }

    os_log(.debug, log: log, "viewDidLoad END")
  }

  override public func viewWillAppear(_ animated: Bool) {
    os_log(.debug, log: log, "viewWillAppear BEGIN")
    super.viewWillAppear(animated)

    playButton.setImage(UIImage(named: "stop"), for: [.highlighted, .selected])
    bypassButton.setImage(UIImage(named: "bypassed"), for: [.highlighted, .selected])
    os_log(.debug, log: log, "viewWillAppear END")
  }

  public func stopPlaying() {
    os_log(.debug, log: log, "stopPlaying BEGIN")
    playButton.isSelected = false
    playButton.isEnabled = false
    bypassButton.isEnabled = false
    bypassButton.isSelected = false
    audioUnitLoader.cleanup()
    os_log(.debug, log: log, "stopPlaying END")
  }
}

// MARK: - Actions

extension HostUIViewController {

  @IBAction public func togglePlay(_ sender: UIButton) {
    os_log(.debug, log: log, "togglePlay BEGIN")
    let isPlaying = audioUnitLoader.togglePlayback()
    bypassButton.isEnabled = isPlaying
    playButton.isSelected = isPlaying
    playButton.tintColor = isPlaying ? .systemYellow : .systemTeal

    if !isPlaying {
      bypassButton.isSelected = false
    }
    os_log(.debug, log: log, "togglePlay END")
  }

  @IBAction public func toggleBypass(_ sender: UIButton) {
    os_log(.debug, log: log, "toggleBypass BEGIN")
    let wasBypassed = auAudioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    auAudioUnit?.shouldBypassEffect = isBypassed
    sender.isSelected = isBypassed
    os_log(.debug, log: log, "toggleBypass END")
  }

  @IBAction public func visitAppStore(_ sender: UIButton) {
    os_log(.debug, log: log, "visitAppStore BEGIN")
    guard let config = self.config else { return }
    guard let url = URL(string: "https://itunes.apple.com/app/id\(config.appStoreId)") else {
      fatalError("Expected a valid URL")
    }

    config.appStoreVisitor(url)
    os_log(.debug, log: log, "visitAppStore END")
  }

  @IBAction public func useFactoryPreset(_ sender: UISegmentedControl? = nil) {
    os_log(.debug, log: log, "useFactoryPreset BEGIN - %d", presetSelection.selectedSegmentIndex)
    userPresetsManager?.makeCurrentPreset(number: presetSelection.selectedSegmentIndex)
    presetName.text = auAudioUnit?.factoryPresetsNonNil[presetSelection.selectedSegmentIndex].name
    os_log(.debug, log: log, "useFactoryPreset END")
  }

  @IBAction public func dismissInstructions(_ sender: Any) {
    instructions.isHidden = true
    UserDefaults.standard.set(true, forKey: showedInitialAlert)
  }
}

// MARK: - AudioUnitHostDelegate

extension HostUIViewController: AudioUnitLoaderDelegate {

  public func connected(audioUnit: AVAudioUnit, viewController: UIViewController) {
    os_log(.debug, log: log, "connected BEGIN")
    userPresetsManager = .init(for: audioUnit.auAudioUnit)
    avAudioUnit = audioUnit
    audioUnitViewController = viewController
    connectFilterView(audioUnit, viewController)
    connectParametersToControls(audioUnit.auAudioUnit)
    os_log(.debug, log: log, "connected END")
  }

  public func failed(error: AudioUnitLoaderError) {
    os_log(.error, log: log, "failed BEGIN - error: %{public}s", error.description)
    let message = "Unable to load the AUv3 component. \(error.description)"
    notify(title: "AUv3 Failure", message: message)
    os_log(.debug, log: log, "failed END")
  }
}

// MARK: - Private

extension HostUIViewController {

  private func connectFilterView(_ audioUnit: AVAudioUnit, _ viewController: UIViewController) {
    os_log(.debug, log: log, "connectFilterView BEGIN")
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
    os_log(.debug, log: log, "connectFilterView END")
  }

  public func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    os_log(.debug, log: log, "connectParametersToControls BEGIN")
    guard let parameterTree = audioUnit.parameterTree else {
      fatalError("FilterAudioUnit does not define any parameters.")
    }

    audioUnitLoader.restore()
    updatePresetMenu()

    allParameterValuesObserverToken = audioUnit.observe(\.allParameterValues) { [weak self] _, _ in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "allParameterValues changed")
      DispatchQueue.main.async { self.updateView() }
    }

    parameterTreeObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, _ in
      guard let self = self else { return }
      os_log(.debug, log: self.log, "parameterTree changed - %d", address)
      DispatchQueue.main.async { self.updateView() }
    })
    os_log(.debug, log: log, "connectParametersToControls END")
  }

  public func usePreset(number: Int) {
    os_log(.debug, log: log, "usePreset BEGIN")
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(number: number)
    updatePresetMenu()
    os_log(.debug, log: log, "usePreset BEGIN")
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
    os_log(.debug, log: log, "updateView BEGIN")
    guard let auAudioUnit = auAudioUnit else { return }
    updatePresetMenu()
    updatePresetSelection(auAudioUnit)
    audioUnitLoader.save()
    os_log(.debug, log: log, "updateView END")
  }

  private func updatePresetSelection(_ auAudioUnit: AUAudioUnit) {
    os_log(.debug, log: log, "updatePresetSelection BEGIN")
    if let presetNumber = auAudioUnit.currentPreset?.number {
      os_log(.info, log: log, "updatePresetSelection: %d", presetNumber)
      presetSelection.selectedSegmentIndex = presetNumber
    } else {
      presetSelection.selectedSegmentIndex = -1
    }
    os_log(.debug, log: log, "updatePresetSelection END")
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
