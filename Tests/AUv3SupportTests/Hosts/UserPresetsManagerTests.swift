import AudioUnit
import XCTest
@testable import AUv3Support

private class MockAudioUnit: NSObject, AUAudioUnitPresetsFacade {
  let supportsUserPresets: Bool = true

  static let log = Shared.logger("SubSystem", "Category")
  private let log = MockAudioUnit.log

  var factoryPresets: [AUAudioUnitPreset]? = [.init(number: 0, name: "Zero"),
                                              .init(number: 1, name: "One")
  ]
  var userPresets: [AUAudioUnitPreset] = [.init(number: -9, name: "The User 1"),
                                          .init(number: -4, name: "A User 2"),
                                          .init(number: -3, name: "Blah User 3")
  ]

  dynamic var currentPreset: AUAudioUnitPreset? = nil

  func saveUserPreset(_ preset: AUAudioUnitPreset) throws {
    if let found = userPresets.firstIndex(where: { $0.number == preset.number }) {
      userPresets[found] = preset
    } else {
      userPresets.append(preset)
    }
  }

  func deleteUserPreset(_ preset: AUAudioUnitPreset) throws {
    userPresets.removeAll { $0.number == preset.number }
  }
}

class UserPresetsManagerTests: XCTestCase {

  private var mock: MockAudioUnit!
  private var upm: UserPresetsManager!

  override func setUpWithError() throws {
    mock = MockAudioUnit()
    upm = UserPresetsManager(for: mock)
  }

  override func tearDownWithError() throws {
    mock = nil
    upm = nil
  }

  func testAPI() throws {

    XCTAssertEqual(upm.presets.count, mock.userPresets.count)

    XCTAssertEqual(upm.presetsOrderedByName[0], mock.userPresets[1])
    XCTAssertEqual(upm.presetsOrderedByName[1], mock.userPresets[2])
    XCTAssertEqual(upm.presetsOrderedByName[2], mock.userPresets[0])

    XCTAssertEqual(upm.presetsOrderedByNumber[0], mock.userPresets[2])
    XCTAssertEqual(upm.presetsOrderedByNumber[1], mock.userPresets[1])
    XCTAssertEqual(upm.presetsOrderedByNumber[2], mock.userPresets[0])

    XCTAssertNil(upm.currentPreset)
  }

  func testNoPresets() {
    mock.factoryPresets = nil
    mock.userPresets = []
    upm = UserPresetsManager(for: mock)

    XCTAssertNotNil(mock.factoryPresetsNonNil)
    XCTAssertEqual(mock.factoryPresetsNonNil.count, 0)
    XCTAssertEqual(upm.nextNumber, -1)
    XCTAssertEqual(upm.nextNumber, -1)

    XCTAssertNoThrow(upm.makeCurrentPreset(number: 0))
    XCTAssertNil(upm.currentPreset)
  }

  func testMakeCurrent() {
    upm.makeCurrentPreset(name: "blah")
    XCTAssertNil(upm.currentPreset)
    upm.makeCurrentPreset(name: "A User 2")
    XCTAssertEqual(upm.currentPreset, mock.userPresets[1])
    upm.clearCurrentPreset()
    XCTAssertNil(upm.currentPreset)
    upm.makeCurrentPreset(number: 0)
    XCTAssertEqual(upm.currentPreset, mock.factoryPresetsNonNil[0])
    upm.makeCurrentPreset(number: 1)
    XCTAssertEqual(upm.currentPreset, mock.factoryPresetsNonNil[1])
  }

  func testFind() throws {
    XCTAssertNil(upm.find(name: "Boba Fett"))
    XCTAssertNil(upm.find(name: "the user 1"))
    XCTAssertEqual(upm.find(name: "The User 1"), mock.userPresets[0])

    XCTAssertNil(upm.find(number: -99))
    XCTAssertNil(upm.find(number: 0))
    XCTAssertEqual(upm.find(number: -4), mock.userPresets[1])
  }

  func testNextNumber() throws {
    XCTAssertEqual(upm.nextNumber, -1)
  }

  func testCreate() throws {
    try upm.create(name: "A New Hope")
    XCTAssertNotNil(upm.currentPreset)
    XCTAssertEqual(upm.currentPreset?.number, -1)
    XCTAssertEqual(upm.currentPreset?.name, "A New Hope")
    XCTAssertEqual(upm.presetsOrderedByName.map { $0.name },
                   ["A New Hope", "A User 2", "Blah User 3", "The User 1"])
    try upm.create(name: "Another")
    try upm.create(name: "And Another")
    try upm.create(name: "And Another 1")
    try upm.create(name: "And Another 2")
  }

  func testDeleteCurrent() throws {
    upm.makeCurrentPreset(number: 1)
    try upm.deleteCurrent()
    XCTAssertNotNil(upm.currentPreset)

    upm.makeCurrentPreset(number: -9)
    XCTAssertNotNil(upm.currentPreset)
    try upm.deleteCurrent()
    XCTAssertNil(upm.currentPreset)

    XCTAssertEqual(upm.presetsOrderedByName.map { $0.name },
                   ["A User 2", "Blah User 3"])
    upm.makeCurrentPreset(number: -9)
    XCTAssertNil(upm.currentPreset)

    upm.makeCurrentPreset(number: 0)
    try upm.deleteCurrent()
  }

  func testUpdate() throws {
    let preset = mock.userPresets[0]
    mock.currentPreset = preset
    let update = AUAudioUnitPreset(number: preset.number, name: "Skippy")
    try upm.update(preset: update)
    XCTAssertEqual(upm.currentPreset?.name, "Skippy")
    XCTAssertEqual(upm.presetsOrderedByName.map { $0.name },
                   ["A User 2", "Blah User 3", "Skippy"])

    upm.makeCurrentPreset(number: 0)
    try upm.update(preset: AUAudioUnitPreset(number: 1, name: "Blah"))
  }

  func testRename() throws {
    upm.makeCurrentPreset(number: -4)
    XCTAssertNotNil(upm.currentPreset)
    try upm.renameCurrent(to: "Crisis")
    XCTAssertNotNil(upm.currentPreset)
    XCTAssertEqual(upm.currentPreset?.name, "Crisis")
    XCTAssertEqual(upm.presetsOrderedByName.map { $0.name },
                   ["Blah User 3", "Crisis", "The User 1"])

    upm.makeCurrentPreset(number: 0)
    try upm.renameCurrent(to: "Blah")
  }
}
