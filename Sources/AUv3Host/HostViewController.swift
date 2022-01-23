// Copyright © 2022 Brad Howes. All rights reserved.

#if os(iOS)

import AUv3Support
import AVKit
import UIKit
import os.log

open class HostViewController: UIViewController {
  private static let log = Logging.logger("HostViewController")
  private var log: OSLog { Self.log }

  private let showedInitialAlert = "showedInitialAlert"

  private var audioUnitHost: AudioUnitHost!
  public var userPresetsManager: UserPresetsManager?

  public var avAudioUnit: AVAudioUnit?
  public var auAudioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }
  public var audioUnitViewController: ViewController?

  @IBOutlet public var presetSelection: UISegmentedControl!
  @IBOutlet public var reviewButton: UIButton!
  @IBOutlet public var playButton: UIButton!
  @IBOutlet public var bypassButton: UIButton!
  @IBOutlet public var containerView: UIView!
  @IBOutlet public weak var instructions: UIView!
  @IBOutlet public var userPresetsMenuButton: UIButton!

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

extension HostViewController {

  override open func viewDidLoad() {
    super.viewDidLoad()

    let version = Bundle.main.releaseVersionNumber
    reviewButton.setTitle(version, for: .normal)

    presetSelection.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    presetSelection.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)

    instructions.layer.borderWidth = 4
    instructions.layer.borderColor = UIColor.systemOrange.cgColor
    instructions.layer.cornerRadius = 16
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    playButton.setImage(UIImage(named: "stop"), for: [.highlighted, .selected])
    bypassButton.setImage(UIImage(named: "bypassed"), for: [.highlighted, .selected])

    audioUnitHost.delegate = self
  }

  open func stopPlaying() {
    audioUnitHost.cleanup()
  }
}

// MARK: - Actions

extension HostViewController {

  @IBAction open func togglePlay(_ sender: UIButton) {
    let isPlaying = audioUnitHost.togglePlayback()
    sender.isSelected = isPlaying
    sender.tintColor = isPlaying ? .systemYellow : .systemTeal
  }

  @IBAction open func toggleBypass(_ sender: UIButton) {
    let wasBypassed = auAudioUnit?.shouldBypassEffect ?? false
    let isBypassed = !wasBypassed
    auAudioUnit?.shouldBypassEffect = isBypassed
    sender.isSelected = isBypassed
  }

  @IBAction open func visitAppStore(_ sender: UIButton) {
    let appStoreId = Bundle.main.appStoreId
    guard let url = URL(string: "https://itunes.apple.com/app/id\(appStoreId)") else {
      fatalError("Expected a valid URL")
    }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  @IBAction open func useFactoryPreset(_ sender: UISegmentedControl? = nil) {
    userPresetsManager?.makeCurrentPreset(number: presetSelection.selectedSegmentIndex)
  }

  @IBAction open func dismissInstructions(_ sender: Any) {
    instructions.isHidden = true
    UserDefaults.standard.set(true, forKey: showedInitialAlert)
  }
}

// MARK: - AudioUnitHostDelegate

extension HostViewController: AudioUnitHostDelegate {

  open func connected(audioUnit: AVAudioUnit, viewController: ViewController) {
    userPresetsManager = .init(for: audioUnit.auAudioUnit)
    avAudioUnit = audioUnit
    audioUnitViewController = viewController
    connectFilterView(audioUnit, viewController)
  }

  open func failed(error: AudioUnitHostError) {
    let message = "Unable to load the AUv3 component. \(error.description)"
    let controller = UIAlertController(title: "AUv3 Failure", message: message, preferredStyle: .alert)
    present(controller, animated: true)
  }
}

// MARK: - Private

extension HostViewController {

  open func showInstructions() {
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

  open func connectFilterView(_ audioUnit: AVAudioUnit, _ viewController: ViewController) {
    containerView.addSubview(viewController.view)
    viewController.view.pinToSuperviewEdges()

    addChild(viewController)
    view.setNeedsLayout()
    containerView.setNeedsLayout()

    let presetCount = auAudioUnit?.factoryPresetsNonNil.count ?? 0
    while presetSelection.numberOfSegments < presetCount {
      let index = presetSelection.numberOfSegments + 1
      presetSelection.insertSegment(withTitle: "\(index)", at: index - 1, animated: false)
    }
    while presetSelection.numberOfSegments > presetCount {
      presetSelection.removeSegment(at: presetSelection.numberOfSegments - 1, animated: false)
    }
  }

  open func connectParametersToControls(_ audioUnit: AUAudioUnit) {
    guard let parameterTree = audioUnit.parameterTree else {
      fatalError("FilterAudioUnit does not define any parameters.")
    }

    audioUnitHost.restore()
    updatePresetMenu()

    allParameterValuesObserverToken = audioUnit.observe(\.allParameterValues) { [weak self] _, _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "allParameterValues changed")
      DispatchQueue.performOnMain { self.updateView() }
    }

    parameterTreeObserverToken = parameterTree.token(byAddingParameterObserver: { [weak self] address, _ in
      guard let self = self else { return }
      os_log(.info, log: self.log, "MainViewController - parameterTree changed - %d", address)
      DispatchQueue.performOnMain { self.updateView() }
    })
  }

  open func usePreset(number: Int) {
    guard let userPresetManager = userPresetsManager else { return }
    userPresetManager.makeCurrentPreset(number: number)
    updatePresetMenu()
  }

  private func updatePresetMenu() {
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

    let actionsGroup = UIMenu(title: "Actions", options: .displayInline,
                              children: active < 0 ? [saveAction, renameAction, deleteAction] : [saveAction])

    let menu = UIMenu(title: "Presets", options: [], children: [userPresetsMenu, factoryPresetsMenu, actionsGroup])

    if #available(iOS 14.0, *) {
      userPresetsMenuButton.menu = menu
      userPresetsMenuButton.showsMenuAsPrimaryAction = true
    }
  }

  private func updateView() {
    guard let auAudioUnit = auAudioUnit else { return }
    updatePresetMenu()
    updatePresetSelection(auAudioUnit)
    audioUnitHost.save()
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

extension HostViewController {

  open func notify(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .default))
    present(controller, animated: true)
  }

  open func yesOrNo(title: String, message: String, continuation: @escaping (UIAlertAction) -> Void) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(.init(title: "Continue", style: .default, handler: continuation))
    controller.addAction(.init(title: "Cancel", style: .cancel))
    present(controller, animated: true)
  }
}

#endif
