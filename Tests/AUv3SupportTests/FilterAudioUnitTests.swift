import AudioToolbox
import AVFoundation
import CoreAudioKit
import DSPHeaders

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

@MainActor
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

private struct formatter: AUParameterFormatting {
  public var unitSeparator: String { " " }
  public var suffix: String { "blah" }
  public var stringFormatForDisplayValue: String { "%.3f" }
}

fileprivate class Kernel: AudioRenderer {

  func bridge() -> DSPHeaders.TypeErasedKernel { DSPHeaders.TypeErasedKernel() }

  var bypass = false
  func getBypass() -> Bool { return bypass }
  func setBypass(_ value: Bool) { bypass = value }

  func getParameterValueObserverBlock() -> AUImplementorValueObserver { self.set }
  func getParameterValueProviderBlock() -> AUImplementorValueProvider { self.get }

  var parameterValueObserverBlock: AUImplementorValueObserver { self.set }
  var parameterValueProviderBlock: AUImplementorValueProvider { self.get }

  var busCount: Int = 0
  var format: AVAudioFormat = .init(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true)!
  var maxFramesToRender: AUAudioFrameCount = 0

  var firstParam: AUValue = 0.0
  var secondParam: AUValue = 0.0

  var renderCount = 0

  func setRenderingFormat(_ busCount: Int, _ format: AVAudioFormat, _ maxFramesToRender: AUAudioFrameCount) {
    self.busCount = busCount
    self.format = format
    self.maxFramesToRender = maxFramesToRender
  }

  func deallocateRenderResources() {
    maxFramesToRender = 0
  }

  var internalRenderBlock: AUInternalRenderBlock {
    let kernel = self
    return { flags, timestamp, frameCount, outputBus, audioBuffer, eventsList, pullInputBlock in
      kernel.renderCount += 1
      return noErr
    }
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

nonisolated(unsafe) private var mockUserPresets = [Int : [AUValue]]()

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

@MainActor
private final class Context {
  let parameters: Parameters
  let kernel: Kernel
  var audioUnit: FilterAudioUnit?
  let control: MockControl
  var editor: FloatParameterEditor?

  init() throws {
    parameters = Parameters()
    kernel = Kernel()
    audioUnit = try FilterAudioUnit(componentDescription: acd)
    audioUnit?.configure(parameters: parameters, kernel: kernel)
    control = MockControl()
//    editor = FloatParameterEditor(parameter: parameters.parameters[0],
//                                  formatting: formatter(), rangedControl: control,
//                                  label: nil)
  }
}

final class FilterAudioUnitTests: XCTestCase {

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

  @MainActor
  func testInitialState() throws {
    let ctx = try Context()
    XCTAssertFalse(ctx.audioUnit?.shouldBypassEffect ?? true)
    XCTAssertTrue(ctx.audioUnit?.canProcessInPlace ?? false)
    XCTAssertTrue(ctx.audioUnit?.supportsUserPresets ?? false)
    XCTAssertEqual(ctx.audioUnit?.inputBusses.count, 1)
    XCTAssertEqual(ctx.audioUnit?.outputBusses.count, 1)
  }

  @MainActor
  func testDisappears() throws {
    let ctx = try Context()
    let param = ctx.parameters.parameterTree.parameter(withAddress: 123)!
    XCTAssertEqual(param.value, 10.0)
    param.setValue(15.0, originator: nil)
    XCTAssertEqual(param.value, 15.0)
    ctx.audioUnit = nil
    param.setValue(10.0, originator: nil)
    XCTAssertEqual(param.value, 10.0)
  }

  @MainActor
  func testSetParameterTreeIsIgnored() throws {
    let ctx = try Context()
    ctx.audioUnit?.parameterTree = AUParameterTree()
    XCTAssertEqual(ctx.audioUnit?.parameterTree, ctx.parameters.parameterTree)
  }

  @MainActor
  func testNames() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.audioUnit?.audioUnitShortName, nil)
    XCTAssertEqual(ctx.audioUnit?.audioUnitName, "AUDelay")
  }

  @MainActor
  func testConfigure() throws {
    let ctx = try Context()
    XCTAssertNotNil(ctx.audioUnit?.currentPreset)
    XCTAssertEqual(ctx.audioUnit?.currentPreset?.number, ctx.parameters.factoryPresets.first?.number)
    XCTAssertNotNil(ctx.audioUnit?.parameterTree)
    XCTAssertEqual(ctx.audioUnit?.factoryPresets?.count, 2)
  }

  @MainActor
  func testClearCurrentPresetIfFactoryPreset() throws {
    let ctx = try Context()
    XCTAssertNotNil(ctx.audioUnit?.currentPreset)
    ctx.audioUnit?.clearCurrentPresetIfFactoryPreset()
    XCTAssertNil(ctx.audioUnit?.currentPreset)
  }

  @MainActor
  func testShouldBypassEffect() throws {
    let ctx = try Context()
    XCTAssertFalse(ctx.audioUnit?.shouldBypassEffect ?? true)
    ctx.audioUnit?.shouldBypassEffect = true
    XCTAssertTrue(ctx.audioUnit?.shouldBypassEffect ?? false)
    XCTAssertTrue(ctx.kernel.bypass)
  }

  @MainActor
  func testFullStateHasPresetInfo() throws {
    let ctx = try Context()
    let state = ctx.audioUnit?.fullState
    XCTAssertNotNil(state)
    XCTAssertEqual(state?[kAUPresetNumberKey] as? NSNumber, 0)
    XCTAssertEqual(state?[kAUPresetNameKey] as? String, "Preset 1")
  }

  @MainActor
  func testSettingFullStateChangesCurrentPreset() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.audioUnit?.currentPreset?.number, 0)
    var state = ctx.audioUnit?.fullState
    XCTAssertNotNil(state)
    state?[kAUPresetNumberKey] = 1
    ctx.audioUnit?.fullState = state
    XCTAssertEqual(ctx.audioUnit?.currentPreset?.number, 1)

    state?.removeValue(forKey: kAUPresetNumberKey)
    ctx.audioUnit?.fullState = state
    XCTAssertNil(ctx.audioUnit?.currentPreset)

    state?.removeValue(forKey: kAUPresetNameKey)
    ctx.audioUnit?.fullState = state
    XCTAssertNil(ctx.audioUnit?.currentPreset)
  }

  @MainActor
  func testAllocateResources() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.kernel.maxFramesToRender, 0)
    try ctx.audioUnit?.allocateRenderResources()
    XCTAssertEqual(ctx.kernel.maxFramesToRender, 512)
    XCTAssertEqual(ctx.kernel.busCount, 1)
    ctx.audioUnit?.deallocateRenderResources()
    XCTAssertEqual(ctx.kernel.maxFramesToRender, 0)
  }

  @MainActor
  func testAllocateResourcesThrowsOnChannelCountMismatch() throws {
    let ctx = try Context()
    let format1 = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    try ctx.audioUnit?.inputBusses[0].setFormat(format1)
    let format2 = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    try ctx.audioUnit?.outputBusses[0].setFormat(format2)
    XCTAssertThrowsError(try ctx.audioUnit?.allocateRenderResources())
  }

  @MainActor
  func testUseFactoryPreset() throws {
    try XCTSkipIf(true, "Broken")
    let ctx = try Context()
    ctx.control.expectation = expectation(description: "control updated")
    XCTAssertEqual(ctx.kernel.firstParam, 10.0)
    XCTAssertEqual(ctx.kernel.secondParam, 11.0)
    ctx.audioUnit?.currentPreset = AUAudioUnitPreset(number: 1, name: "Blah")
    XCTAssertEqual(ctx.kernel.firstParam, 20.0)
    XCTAssertEqual(ctx.kernel.secondParam, 21.0)
    waitForExpectations(timeout: 10.0)
    XCTAssertEqual(ctx.control.value, 20.0)
  }

  @MainActor
  func testUseUserPreset() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.kernel.firstParam, 10.0)
    XCTAssertEqual(ctx.kernel.secondParam, 11.0)
    try ctx.audioUnit?.saveUserPreset(AUAudioUnitPreset(number: -1, name: "Boo"))
    ctx.audioUnit?.currentPreset = AUAudioUnitPreset(number: 1, name: "Blah")
    XCTAssertEqual(ctx.kernel.firstParam, 20.0)
    XCTAssertEqual(ctx.kernel.secondParam, 21.0)
    ctx.audioUnit?.currentPreset = AUAudioUnitPreset(number: -1, name: "Boo")
    XCTAssertEqual(ctx.kernel.firstParam, 10.0)
    XCTAssertEqual(ctx.kernel.secondParam, 11.0)
    ctx.audioUnit?.currentPreset = AUAudioUnitPreset(number: -99, name: "Barf")
  }

  @MainActor
  func testParameterChanges() throws {
    let ctx = try Context()
    XCTAssertEqual(ctx.kernel.maxFramesToRender, 0)
    XCTAssertEqual(ctx.kernel.firstParam, 10.0)
    XCTAssertEqual(ctx.kernel.secondParam, 11.0)

    ctx.parameters.parameters[0].setValue(12.34, originator: nil)
    XCTAssertEqual(ctx.kernel.firstParam, 12.34)
    ctx.parameters.parameters[1].setValue(56.78, originator: nil)
    XCTAssertEqual(ctx.kernel.secondParam, 56.78)
  }

  @MainActor
  func testInternalRenderBlock() throws {
    let ctx = try Context()
    XCTAssertNotNil(ctx.audioUnit?.renderBlock)
    XCTAssertNotNil(ctx.audioUnit?.internalRenderBlock)
    XCTAssertEqual(ctx.kernel.renderCount, 0)

    let buffer = AVAudioPCMBuffer(pcmFormat: .init(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2,
                                                   interleaved: false)!, frameCapacity: 512)!

    var flags: UInt32 = .init()
    var timestamp: AudioTimeStamp = .init()
    let frameCount: AUAudioFrameCount = 1
    let outputBus: Int = 0
    let bufferList: UnsafeMutablePointer<AudioBufferList> = buffer.mutableAudioBufferList
    let eventList: UnsafePointer<AURenderEvent>? = nil
    let pullInputBlock: AURenderPullInputBlock? = nil
    let result = ctx.audioUnit?.internalRenderBlock(&flags, &timestamp, frameCount, outputBus, bufferList,
                                                    eventList, pullInputBlock)
    XCTAssertEqual(result, -1)
    XCTAssertEqual(ctx.kernel.renderCount, 0)
  }

  @MainActor
  func testParametersForOverview() throws {
    let ctx = try Context()
    var indices = ctx.audioUnit?.parametersForOverview(withCount: 1) ?? []
    XCTAssertEqual(indices.count, 1)
    XCTAssertEqual(indices[0], 123)
    indices = ctx.audioUnit?.parametersForOverview(withCount: 2) ?? []
    XCTAssertEqual(indices.count, 2)
    XCTAssertEqual(indices[0], 123)
    XCTAssertEqual(indices[1], 456)
  }

  @MainActor
  func testViewManagement() throws {
    let ctx = try Context()
    XCTAssertNil(ctx.audioUnit?.viewConfigurationManager)
    XCTAssertEqual(IndexSet(integersIn: 0..<2), ctx.audioUnit?.supportedViewConfigurations([
      .init(width: 0, height: 0, hostHasController: false),
      .init(width: 1, height: 0, hostHasController: false)
    ]))

    let mvcm = MockViewConfigurationManager()
    ctx.audioUnit?.viewConfigurationManager = mvcm
    XCTAssertEqual(IndexSet(integersIn: 0..<2), ctx.audioUnit?.supportedViewConfigurations([
      .init(width: 0, height: 0, hostHasController: false),
      .init(width: 1, height: 0, hostHasController: false)
    ]))

    ctx.audioUnit?.select(.init(width: 100, height: 200, hostHasController: false))
    XCTAssertEqual(mvcm.activeViewConfiguration?.width, 100)
    XCTAssertEqual(mvcm.activeViewConfiguration?.height, 200)
  }
}
