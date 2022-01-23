// Copyright © 2020 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Host
import XCTest

class MockAUAudioUnit: AUAudioUnitPresetsFacade {
  var factoryPresetsNonNil = [AUAudioUnitPreset]()
  var userPresets = [AUAudioUnitPreset]()
  var currentPreset: AUAudioUnitPreset?
  func saveUserPreset(_ preset: AUAudioUnitPreset) throws {
    try deleteUserPreset(preset)
    userPresets.append(preset)
  }

  func deleteUserPreset(_ preset: AUAudioUnitPreset) throws {
    if let index = userPresets.firstIndex(where: { $0.number == preset.number }) {
      userPresets.remove(at: index)
    }
  }
}

class UserPresetsManagerTests: XCTestCase {
  var manager: UserPresetsManager!

  override func setUp() {
    let audioUnit = MockAUAudioUnit()
    audioUnit.userPresets = [
      AUAudioUnitPreset(number: -2, name: "two"),
      AUAudioUnitPreset(number: -3, name: "Three"),
      AUAudioUnitPreset(number: -1, name: "One"),
      AUAudioUnitPreset(number: -5, name: "five")
    ]

    audioUnit.factoryPresetsNonNil = [
      AUAudioUnitPreset(number: 0, name: "fac 1"),
      AUAudioUnitPreset(number: 1, name: "fac 2")
    ]
    audioUnit.currentPreset = audioUnit.factoryPresetsNonNil[0]
    manager = UserPresetsManager(for: audioUnit)
  }

  func testFind() throws {
    XCTAssertEqual(-1, manager.find(name: "One")?.number)
    XCTAssertEqual(-2, manager.find(name: "two")?.number)
    XCTAssertNil(manager.find(name: "four"))
  }

  func testClearCurrentPreset() throws {
    XCTAssertNotNil(manager.audioUnit.currentPreset)
    manager.clearCurrentPreset()
    XCTAssertNil(manager.audioUnit.currentPreset)
  }

  func testMakeCurrentPresetByName() {
    XCTAssertNotEqual(manager.audioUnit.currentPreset?.name, "five")
    manager.makeCurrentPreset(name: "five")
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "five")
    manager.makeCurrentPreset(name: "four")
    XCTAssertNil(manager.audioUnit.currentPreset)
  }

  func testMakeCurrentPresetByFactoryIndex() {
    XCTAssertNotEqual(manager.audioUnit.currentPreset?.name, "fac 2")
    manager.makeCurrentPreset(number: 1)
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "fac 2")
    manager.makeCurrentPreset(number: 2)
    XCTAssertNil(manager.audioUnit.currentPreset)
    manager.makeCurrentPreset(number: 99)
    XCTAssertNil(manager.audioUnit.currentPreset)
  }

  func testMakeCurrentPresetByUserIndex() {
    XCTAssertNotEqual(manager.audioUnit.currentPreset?.name, "fac 2")
    manager.makeCurrentPreset(number: -1)
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "One")
    manager.makeCurrentPreset(number: -2)
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "two")
    manager.makeCurrentPreset(number: -4)
    XCTAssertNil(manager.audioUnit.currentPreset)
  }

  func testNextNumber() throws {
    XCTAssertEqual(-4, manager.nextNumber)
    try manager.create(name: "four")
    XCTAssertEqual(-6, manager.nextNumber)
    let audioUnit = manager.audioUnit as! MockAUAudioUnit
    audioUnit.userPresets.removeAll()
    XCTAssertEqual(-1, manager.nextNumber)
  }

  func testCreate() throws {
    XCTAssertNil(manager.find(name: "four"))
    XCTAssertEqual(-4, manager.nextNumber)
    try manager.create(name: "four")
    XCTAssertEqual(manager.audioUnit.currentPreset?.number, -4)
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "four")
    XCTAssertNotNil(manager.find(name: "four"))
  }

  func testUpdate() throws {
    let preset = manager.find(name: "Three")!
    try manager.update(preset: preset)
    XCTAssertTrue(preset !== manager.find(name: "Three"))
    XCTAssertEqual(manager.audioUnit.currentPreset, manager.find(name: "Three"))
    XCTAssertEqual(1, manager.audioUnit.userPresets.filter { $0.number == -3 }.count)
  }

  func testRenameCurrent() throws {
    manager.makeCurrentPreset(name: "five")
    try manager.renameCurrent(to: "five-oh")
    XCTAssertNil(manager.find(name: "five"))
    XCTAssertNotNil(manager.find(name: "five-oh"))
    XCTAssertEqual(manager.audioUnit.currentPreset?.name, "five-oh")
    XCTAssertEqual(manager.audioUnit.currentPreset?.number, -5)
    XCTAssertEqual(1, manager.audioUnit.userPresets.filter { $0.number == -5 }.count)
    manager.clearCurrentPreset()
    try manager.renameCurrent(to: "blah")
  }

  func testDeleteCurrent() throws {
    manager.makeCurrentPreset(name: "Three")
    try manager.deleteCurrent()
    XCTAssertNil(manager.find(name: "Three"))
    XCTAssertNil(manager.audioUnit.currentPreset)
    XCTAssertEqual(0, manager.audioUnit.userPresets.filter { $0.number == -3 }.count)
    let count = manager.presets.count
    manager.clearCurrentPreset()
    try manager.deleteCurrent()
    XCTAssertEqual(count, manager.presets.count)
  }

  func testOrderedByNumber() {
    let numbers = manager.presetsOrderedByNumber.map { $0.number }
    XCTAssertEqual([-1, -2, -3, -5], numbers)
  }

  func testOrderedByName() {
    let names = manager.presetsOrderedByName.map { $0.name }
    XCTAssertEqual(["five", "One", "Three", "two"], names)
  }
}
