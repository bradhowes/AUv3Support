import AudioToolbox
import AVFoundation
import CoreAudioKit

import XCTest
@testable import AUv3Support

fileprivate let acd = AudioComponentDescription(componentType: FourCharCode("aufx"),
                                                componentSubType: FourCharCode("dely"),
                                                componentManufacturer: FourCharCode("appl"),
                                                componentFlags: 0, componentFlagsMask: 0)

fileprivate let bad_acd = AudioComponentDescription(componentType: FourCharCode("aufx"),
                                                    componentSubType: FourCharCode("dely"),
                                                    componentManufacturer: FourCharCode("blah"),
                                                    componentFlags: UInt32.max, componentFlagsMask: 0)

fileprivate class MockControl: NSObject, RangedControl {
  static let log = Shared.logger("foo", "bar")
  let log = MockControl.log
  var parameterAddress: UInt64 = 0
  var value: AUValue = 0.0 {
    didSet {
      expectation?.fulfill()
    }
  }
  var minimumValue: Float = 0.0
  var maximumValue: Float = 100.0
  var expectation: XCTestExpectation?
}

fileprivate class Parameters: ParameterSource {

  var parameters: [AUParameter] = [
    AUParameterTree.createParameter(withIdentifier: "First", name: "First Param", address: 123, min: 0, max: 100,
                                    unit: .beats, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable],
                                    valueStrings: nil, dependentParameters: nil),
    AUParameterTree.createParameter(withIdentifier: "Second", name: "Second Param", address: 456, min: 0, max: 100,
                                    unit: .milliseconds, unitName: nil, flags: [.flag_IsReadable, .flag_IsWritable],
                                    valueStrings: nil, dependentParameters: nil),
  ]

  lazy var parameterTree: AUParameterTree = AUParameterTree.createTree(withChildren: parameters)

  var factoryPresets: [AUAudioUnitPreset] = [.init(number: 0, name: "Preset 1"), .init(number: 1, name: "Preset 2")]

  func useFactoryPreset(_ preset: AUAudioUnitPreset) {
    switch preset.number {
    case 0:
      parameters[0].setValue(10.0, originator: nil)
      parameters[1].setValue(11.0, originator: nil)
    case 1:
      parameters[0].setValue(20.0, originator: nil)
      parameters[1].setValue(21.0, originator: nil)
    default: break
    }
  }
}

fileprivate class Kernel: AudioRenderer {

  var bypassed: Bool = false
  var busCount: Int = 0
  var format: AVAudioFormat = .init(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true)!
  var maxFramesToRender: AUAudioFrameCount = 0

  var firstParam: AUValue = 0.0
  var secondParam: AUValue = 0.0

  var renderCount = 0

  func setRenderingFormat(_ busCount: Int, format: AVAudioFormat, maxFramesToRender: AUAudioFrameCount) {
    self.busCount = busCount
    self.format = format
    self.maxFramesToRender = maxFramesToRender
  }

  func deallocateRenderResources() {
    maxFramesToRender = 0
  }

  func internalRenderBlock(_ transportStateBlock: AUHostTransportStateBlock?) -> AUInternalRenderBlock {
    let kernel = self
    return { flags, timestamp, frameCount, outputBus, audioBuffer, eventsList, pullInputBlock in
      kernel.renderCount += 1
      return noErr
    }
  }

  func setBypass(_ state: Bool) {
    bypassed = state
  }

  func set(_ parameter: AUParameter, value: AUValue) {
    switch parameter.address {
    case 123: firstParam = value
    case 456: secondParam = value
    default: break
    }
  }

  func get(_ parameter: AUParameter) -> AUValue {
    switch parameter.address {
    case 123: return firstParam
    case 456: return secondParam
    default: return 0.0
    }
  }
}

fileprivate class MockViewConfigurationManager: AudioUnitViewConfigurationManager {
  var activeViewConfiguration: AUAudioUnitViewConfiguration?

  func selectViewConfiguration(_ viewConfiguration: AUAudioUnitViewConfiguration) {
    activeViewConfiguration = viewConfiguration
  }
}

private var mockUserPresets = [Int : [AUValue]]()

enum RuntimeError: Error {
  case unknownPreset
}

public extension FilterAudioUnit {
  override func saveUserPreset(_ userPreset: AUAudioUnitPreset) throws {
    mockUserPresets[userPreset.number] = [parameterTree!.parameter(withAddress: 123)!.value,
                                          parameterTree!.parameter(withAddress: 456)!.value]
  }

  override func presetState(for userPreset: AUAudioUnitPreset) throws -> [String : Any] {
    if let parameterValues = mockUserPresets[userPreset.number] {
      parameterTree!.parameter(withAddress: 123)!.setValue(parameterValues[0], originator: nil)
      parameterTree!.parameter(withAddress: 456)!.setValue(parameterValues[1], originator: nil)
      return [:]
    }
    throw RuntimeError.unknownPreset
  }
}

final class FilterAudioUnitTests: XCTestCase {

  private var parameters: Parameters!
  private var kernel: Kernel!
  private var audioUnit: FilterAudioUnit!
  private var control: MockControl!
  private var editor: FloatParameterEditor!

  override func setUpWithError() throws {
    parameters = Parameters()
    kernel = Kernel()
    audioUnit = try FilterAudioUnit(componentDescription: acd)
    audioUnit.configure(parameters: parameters, kernel: kernel)
    control = MockControl()
    editor = FloatParameterEditor(parameter: parameters.parameters[0],
                                  formatter: { "\($0)" }, rangedControl: control,
                                  label: nil)
  }

  override func tearDownWithError() throws {
  }

  func testInstantiate() throws {
    let created = expectation(description: "FilterAudioUnit async")
    FilterAudioUnit.instantiate(with: acd) { audioUnit, error in
      guard let _ = audioUnit, error == nil else { XCTFail("failed"); return }
      created.fulfill()
    }

    wait(for: [created], timeout: 5)
  }

  func testInstantiateThatFails() throws {
    let failed = expectation(description: "FilterAudioUnit async")
    FilterAudioUnit.instantiate(with: bad_acd) { audioUnit, error in
      guard audioUnit == nil, error != nil else { XCTFail("unexpected success"); return }
      failed.fulfill()
    }

    wait(for: [failed], timeout: 5)
  }

  func testInitialState() throws {
    XCTAssertFalse(audioUnit.shouldBypassEffect)
    XCTAssertTrue(audioUnit.canProcessInPlace)
    XCTAssertTrue(audioUnit.supportsUserPresets)
    XCTAssertEqual(audioUnit.inputBusses.count, 1)
    XCTAssertEqual(audioUnit.outputBusses.count, 1)
  }

  func testDisappears() throws {
    let param = parameters.parameterTree.parameter(withAddress: 123)!
    XCTAssertEqual(param.value, 10.0)
    param.setValue(15.0, originator: nil)
    XCTAssertEqual(param.value, 15.0)
    audioUnit = nil
    param.setValue(15.0, originator: nil)
    XCTAssertEqual(param.value, 0.0)
  }

  func testSetParameterTreeIsIgnored() throws {
    audioUnit.parameterTree = AUParameterTree()
    XCTAssertEqual(audioUnit.parameterTree, parameters.parameterTree)
  }
  
  func testNames() throws {
    XCTAssertEqual(audioUnit.audioUnitShortName, nil)
    XCTAssertEqual(audioUnit.audioUnitName, "AUDelay")
  }

  func testConfigure() throws {
    XCTAssertNotNil(audioUnit.currentPreset)
    XCTAssertEqual(audioUnit.currentPreset?.number, parameters.factoryPresets.first?.number)
    XCTAssertNotNil(audioUnit.parameterTree)
    XCTAssertEqual(audioUnit.factoryPresets?.count, 2)
  }

  func testClearCurrentPresetIfFactoryPreset() throws {
    XCTAssertNotNil(audioUnit.currentPreset)
    audioUnit.clearCurrentPresetIfFactoryPreset()
    XCTAssertNil(audioUnit.currentPreset)
  }

  func testShouldBypassEffect() throws {
    XCTAssertFalse(audioUnit.shouldBypassEffect)
    audioUnit.shouldBypassEffect = true
    XCTAssertTrue(audioUnit.shouldBypassEffect)
    XCTAssertTrue(kernel.bypassed)
  }

  func testFullStateHasPresetInfo() throws {
    let state = audioUnit.fullState
    XCTAssertNotNil(state)
    XCTAssertEqual(state?[kAUPresetNumberKey] as? NSNumber, 0)
    XCTAssertEqual(state?[kAUPresetNameKey] as? String, "Preset 1")
  }

  func testSettingFullStateChangesCurrentPreset() throws {
    XCTAssertEqual(audioUnit.currentPreset?.number, 0)
    var state = audioUnit.fullState
    XCTAssertNotNil(state)
    state?[kAUPresetNumberKey] = 1
    audioUnit.fullState = state
    XCTAssertEqual(audioUnit.currentPreset?.number, 1)

    state?.removeValue(forKey: kAUPresetNumberKey)
    audioUnit.fullState = state
    XCTAssertNil(audioUnit.currentPreset)

    state?.removeValue(forKey: kAUPresetNameKey)
    audioUnit.fullState = state
    XCTAssertNil(audioUnit.currentPreset)
  }

  func testAllocateResources() throws {
    XCTAssertEqual(kernel.maxFramesToRender, 0)
    try audioUnit.allocateRenderResources()
    XCTAssertEqual(kernel.maxFramesToRender, 512)
    XCTAssertEqual(kernel.busCount, 1)
    audioUnit.deallocateRenderResources()
    XCTAssertEqual(kernel.maxFramesToRender, 0)
  }

  func testAllocateResourcesThrowsOnChannelCountMismatch() throws {
    let format1 = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    try audioUnit.inputBusses[0].setFormat(format1)
    let format2 = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    try audioUnit.outputBusses[0].setFormat(format2)
    XCTAssertThrowsError(try audioUnit.allocateRenderResources())
  }

  func testUseFactoryPreset() throws {
    control.expectation = expectation(description: "control updated")
    XCTAssertEqual(kernel.firstParam, 10.0)
    XCTAssertEqual(kernel.secondParam, 11.0)
    audioUnit.currentPreset = AUAudioUnitPreset(number: 1, name: "Blah")
    XCTAssertEqual(kernel.firstParam, 20.0)
    XCTAssertEqual(kernel.secondParam, 21.0)
    waitForExpectations(timeout: 10.0)
    XCTAssertEqual(control.value, 20.0)
  }

  func testUseUserPreset() throws {
    XCTAssertEqual(kernel.firstParam, 10.0)
    XCTAssertEqual(kernel.secondParam, 11.0)
    try audioUnit.saveUserPreset(AUAudioUnitPreset(number: -1, name: "Boo"))
    audioUnit.currentPreset = AUAudioUnitPreset(number: 1, name: "Blah")
    XCTAssertEqual(kernel.firstParam, 20.0)
    XCTAssertEqual(kernel.secondParam, 21.0)
    audioUnit.currentPreset = AUAudioUnitPreset(number: -1, name: "Boo")
    XCTAssertEqual(kernel.firstParam, 10.0)
    XCTAssertEqual(kernel.secondParam, 11.0)

    audioUnit.currentPreset = AUAudioUnitPreset(number: -99, name: "Barf")
  }

  func testParameterChanges() throws {
    XCTAssertEqual(kernel.maxFramesToRender, 0)
    XCTAssertEqual(kernel.firstParam, 10.0)
    XCTAssertEqual(kernel.secondParam, 11.0)

    parameters.parameters[0].setValue(12.34, originator: nil)
    XCTAssertEqual(kernel.firstParam, 12.34)
    parameters.parameters[1].setValue(56.78, originator: nil)
    XCTAssertEqual(kernel.secondParam, 56.78)
  }

  func testInternalRenderBlock() throws {
    XCTAssertNotNil(audioUnit.renderBlock)
    XCTAssertNotNil(audioUnit.internalRenderBlock)
    XCTAssertEqual(kernel.renderCount, 0)

    let buffer = AVAudioPCMBuffer(pcmFormat: .init(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2,
                                                   interleaved: false)!, frameCapacity: 512)!

    var flags: AudioUnitRenderActionFlags = .init()
    var timestamp: AudioTimeStamp = .init()
    let frameCount: AUAudioFrameCount = 1
    let outputBus: Int = 0
    let bufferList: UnsafeMutablePointer<AudioBufferList> = buffer.mutableAudioBufferList
    let eventList: UnsafePointer<AURenderEvent>? = nil
    let pullInputBlock: AURenderPullInputBlock? = nil
    let result = audioUnit.internalRenderBlock(&flags, &timestamp, frameCount, outputBus, bufferList,
                                               eventList, pullInputBlock)
    XCTAssertEqual(result, noErr)
    XCTAssertEqual(kernel.renderCount, 1)
  }

  func testParametersForOverview() {
    var indices = audioUnit.parametersForOverview(withCount: 1)
    XCTAssertEqual(indices.count, 1)
    XCTAssertEqual(indices[0], 123)
    indices = audioUnit.parametersForOverview(withCount: 2)
    XCTAssertEqual(indices.count, 2)
    XCTAssertEqual(indices[0], 123)
    XCTAssertEqual(indices[1], 456)
  }

  func testViewManagement() {
    XCTAssertNil(audioUnit.viewConfigurationManager)
    XCTAssertEqual(IndexSet(integersIn: 0..<2), audioUnit.supportedViewConfigurations([
      .init(width: 0, height: 0, hostHasController: false),
      .init(width: 1, height: 0, hostHasController: false)
    ]))

    let mvcm = MockViewConfigurationManager()
    audioUnit.viewConfigurationManager = mvcm
    XCTAssertEqual(IndexSet(), audioUnit.supportedViewConfigurations([
      .init(width: 0, height: 0, hostHasController: false),
      .init(width: 1, height: 0, hostHasController: false)
    ]))

    audioUnit.select(.init(width: 100, height: 200, hostHasController: false))
    XCTAssertEqual(mvcm.activeViewConfiguration?.width, 100)
    XCTAssertEqual(mvcm.activeViewConfiguration?.height, 200)
  }
}
