// Copyright © 2022 Brad Howes. All rights reserved.

import os.log
import AudioToolbox

/**
 Subset of AUAudioUnit functionality that is used by UserPresetsManager.
 */
public protocol AUAudioUnitPresetsFacade: AnyObject {

  /// Obtain an array of factory presets that is never nil.
  var factoryPresets: [AUAudioUnitPreset]? { get }

  /// Obtain an array of user presets.
  var userPresets: [AUAudioUnitPreset] { get }

  /// Currently active preset (user or factory). May be nil.
  var currentPreset: AUAudioUnitPreset? { get set }

  /// Save the given user preset.
  func saveUserPreset(_ preset: AUAudioUnitPreset) throws

  /// Delete the given user preset.
  func deleteUserPreset(_ preset: AUAudioUnitPreset) throws
}

extension AUAudioUnitPresetsFacade {

  /// Variation of `factoryPresets` that is never nil.
  public var factoryPresetsNonNil: [AUAudioUnitPreset] { factoryPresets ?? [] }
}

extension AUAudioUnit: AUAudioUnitPresetsFacade {}

/**
 Manager of user presets for the AUv3 component. Supports creation, renaming, and deletion. Also, manages the
 `currentPreset` attribute of the component.
 */
public class UserPresetsManager {
  private let log = Shared.logger("UserPresetsManager")

  /// The slice of the AUv3 component that the manager works with
  public let audioUnit: AUAudioUnitPresetsFacade

  /// The (user) presets straight from the component
  public var presets: [AUAudioUnitPreset] { audioUnit.userPresets }

  /// The (user) presets from the component ordered by preset number in descending order (-1 first)
  public var presetsOrderedByNumber: [AUAudioUnitPreset] { presets.sorted { $0.number > $1.number } }

  /// The (user) presets from the component ordered by preset name in ascending order
  public var presetsOrderedByName: [AUAudioUnitPreset] {
    presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  public var currentPreset: AUAudioUnitPreset? { audioUnit.currentPreset }

  /**
   Create new instance for the given AUv3 component

   - parameter audioUnit: AUv3 component
   */
  public init(for audioUnit: AUAudioUnitPresetsFacade) {
    os_log(.debug, log: log, "init")
    self.audioUnit = audioUnit
  }

  /**
   Locate the user preset with the given name

   - parameter name: the name to look for
   - returns: the preset that was found or nil
   */
  public func find(name: String) -> AUAudioUnitPreset? {
    os_log(.debug, log: log, "find BEGIN - %{public}s", name)
    let found = presets.first(where: { $0.name == name })
    os_log(.debug, log: log, "find END - %{public}s", found.descriptionOrNil)
    return found
  }

  /**
   Locate the user preset with the given number

   - parameter number: the number to look for
   - returns: the preset that was found or nil
   */
  public func find(number: Int) -> AUAudioUnitPreset? {
    os_log(.debug, log: log, "find BEGIN - %d", number)
    let found = presets.first(where: { $0.number == number })
    os_log(.debug, log: log, "find END - %{public}s", found.descriptionOrNil)
    return found
  }

  /// Clear the `currentPreset` attribute of the component.
  public func clearCurrentPreset() {
    audioUnit.currentPreset = nil
  }

  /**
   Make the first user preset with the given name the current preset.

   - parameter name: the name to look for
   */
  public func makeCurrentPreset(name: String) {
    os_log(.debug, log: log, "makeCurrentPreset BEGIN - %{public}s", name)
    audioUnit.currentPreset = find(name: name)
    os_log(.debug, log: log, "makeCurrentPreset END - %{public}s", currentPreset.descriptionOrNil)
  }

  /**
   Make the first user preset with the given preset number the current preset. NOTE: unlike the 'name' version, this
   will access factory presets when the number is non-negative.

   - parameter number: the number to look for
   */
  public func makeCurrentPreset(number: Int) {
    os_log(.debug, log: log, "makeCurrentPreset BEGIN - %d", number)
    if number >= 0 {
      audioUnit.currentPreset = audioUnit.factoryPresetsNonNil[validating: number]
    } else {
      audioUnit.currentPreset = find(number: number)
    }
    os_log(.debug, log: log, "makeCurrentPreset END - %{public}s", currentPreset.descriptionOrNil)
 }

  /**
   Create a new user preset under the given name. The number assigned to the preset is the smallest negative value
   that is not being used by any other user preset. Makes the new preset current.

   - parameter name: the name to use for the preset
   - throws exception from AUAudioUnit
   */
  public func create(name: String) throws {
    os_log(.debug, log: log, "create BEGIN - %{public}s", name)
    let preset = AUAudioUnitPreset(number: nextNumber, name: name)
    try audioUnit.saveUserPreset(preset)
    audioUnit.currentPreset = preset
    os_log(.debug, log: log, "create END - %{public}s", currentPreset.descriptionOrNil)
  }

  /**
   Update a given user preset by saving it again, presumably with new state from the AUv3 component.

   - parameter preset: the existing preset to save
   - throws exception from AUAudioUnit
   */
  public func update(preset: AUAudioUnitPreset) throws {
    os_log(.debug, log: log, "update BEGIN - %d", preset.number)
    guard preset.number < 0 else { return }
    let preset = AUAudioUnitPreset(number: preset.number, name: preset.name)
    try audioUnit.saveUserPreset(preset)
    audioUnit.currentPreset = preset
    os_log(.debug, log: log, "update END - %{public}s", currentPreset.descriptionOrNil)
  }

  /**
   Change the name of the _current_ preset to a new value.

   - parameter name: the new name to use
   - throws exception from AUAudioUnit
   */
  public func renameCurrent(to name: String) throws {
    os_log(.debug, log: log, "rename BEGIN - to: %{public}s", name)
    guard let old = audioUnit.currentPreset, old.number < 0 else { return }
    let new = AUAudioUnitPreset(number: old.number, name: name)
    try audioUnit.deleteUserPreset(old)
    try audioUnit.saveUserPreset(new)
    audioUnit.currentPreset = new
    os_log(.debug, log: log, "rename END - %{public}s", currentPreset.descriptionOrNil)
  }

  /**
   Delete the existing user preset that is currently active.

   - throws exception from AUAudioUnit
   */
  public func deleteCurrent() throws {
    os_log(.debug, log: log, "deleteCurrent BEGIN - to: %{public}s", currentPreset.descriptionOrNil)
    guard let preset = audioUnit.currentPreset, preset.number < 0 else { return }
    audioUnit.currentPreset = nil
    try audioUnit.deleteUserPreset(AUAudioUnitPreset(number: preset.number, name: preset.name))
    os_log(.debug, log: log, "deleteCurrent END - %{public}s", currentPreset.descriptionOrNil)
  }

  /// Obtain the smallest user preset number that is not being used by any other preset.
  public var nextNumber: Int {
    let ordered = presetsOrderedByNumber
    var number = max(ordered.first?.number ?? -1, -1)
    for entry in ordered {
      if entry.number != number {
        break
      }
      number -= 1
    }

    return number
  }
}

public extension RandomAccessCollection {

  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  /// - complexity: O(1)
  /// https://stackoverflow.com/a/68453929/629836
  subscript(validating index: Index) -> Element? {
    index >= startIndex && index < endIndex ? self[index] : nil
  }
}
