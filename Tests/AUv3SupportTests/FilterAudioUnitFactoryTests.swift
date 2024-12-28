import AudioToolbox
import AVFoundation
import CoreAudioKit
import DSPHeaders

import XCTest
@testable import AUv3Support

fileprivate let acd = AudioComponentDescription(componentType: FourCharCode("aufx"), componentSubType: FourCharCode("dely"),
                                                componentManufacturer: FourCharCode("appl"),
                                                componentFlags: 0, componentFlagsMask: 0)

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

  }
}

fileprivate class Kernel: AudioRenderer {

  func bridge() -> DSPHeaders.TypeErasedKernel { DSPHeaders.TypeErasedKernel() }

  var bypass = false
  func getBypass() -> Bool { return bypass }
  func setBypass(_ value: Bool) { bypass = value }

  func getParameterValueObserverBlock() -> AUImplementorValueObserver { self.set }
  func getParameterValueProviderBlock() -> AUImplementorValueProvider { self.get }

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


final class FilterAudioUnitFactoryTests: XCTestCase {

  override func setUpWithError() throws {
  }

  override func tearDownWithError() throws {
  }

  func testCreate() throws {
    let parameters = Parameters()
    let kernel = Kernel()
    let audioUnit = try FilterAudioUnitFactory.create(
      componentDescription: acd, parameters: parameters,
      kernel: kernel,
      viewConfigurationManager: nil
    )
    XCTAssertNotNil(audioUnit)
  }
}
