// Copyright © 2020, 2024 Brad Howes. All rights reserved.

import AudioToolbox

@testable import AUv3Support
import XCTest

fileprivate class MockProvider : ParameterAddressProvider {
  var parameterAddress: AUParameterAddress = 123
}

private final class Context {
  let params: [AUParameter]
  let tree: AUParameterTree
  let expectation: XCTestExpectation?

  init(expectation: XCTestExpectation? = nil) {
    params = [AUParameterTree.createParameter(withIdentifier: "First", name: "First Name", address: 123,
                                              min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                              flags: [.flag_IsReadable], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Second", name: "Second Name", address: 456,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_IsReadable], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Squared", name: "Squared", address: 1,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplaySquared], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "SquareRoot", name: "SquareRoot", address: 2,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplaySquareRoot], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Cubed", name: "Cubed", address: 3,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayCubed], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "CubeRoot", name: "CubeRoot", address: 4,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayCubeRoot], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Logarithmic", name: "Logarithmic", address: 5,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayLogarithmic], valueStrings: nil,
                                              dependentParameters: nil),
              AUParameterTree.createParameter(withIdentifier: "Exponential", name: "Exponential", address: 6,
                                              min: 10.0, max: 200.0, unit: .generic, unitName: nil,
                                              flags: [.flag_DisplayExponential], valueStrings: nil,
                                              dependentParameters: nil),
    ]
    tree = AUParameterTree.createTree(withChildren: params)
    self.expectation = expectation
  }

  func processParameter(address: AUParameterAddress, value: AUValue) {
    expectation?.fulfill()
  }
}

final class AUParameterTreeTests: XCTestCase {

  func testAccessByParameterAddressProvider() {
    let ctx = Context()
    XCTAssertEqual(ctx.tree.parameter(source: MockProvider()), ctx.params[0])
  }

  func testParameterRange() {
    let ctx = Context()
    XCTAssertEqual(ctx.params[0].range, 0.0...100.0)
    XCTAssertEqual(ctx.params[1].range, 10.0...200.0)
  }

  func testParametricValue() {
    XCTAssertEqual(ParametricValue(0.1).value, 0.1)
    XCTAssertEqual(ParametricValue(-0.1).value, 0.0)
    XCTAssertEqual(ParametricValue(1.0).value, 1.0)
    XCTAssertEqual(ParametricValue(1.1).value, 1.0)
  }

  func testParametricSquaredTransforms() {
    let ctx = Context()
    let value = ParametricValue(0.5)
    let param = ctx.params[2]
    param.setParametricValue(value)
    XCTAssertEqual(param.value, 144.35028)
    XCTAssertEqual(param.parametricValue.value, 0.5, accuracy: 1.0e-5)
  }

  func testParametricSquareRootTransforms() {
    let ctx = Context()
    let value = ParametricValue(0.5)
    let param = ctx.params[3]
    param.setParametricValue(value)
    XCTAssertEqual(param.value, 57.5)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricCubedTransforms() {
    let ctx = Context()
    let param = ctx.params[4]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 160.8031)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricCubeRootTransforms() {
    let ctx = Context()
    let param = ctx.params[5]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 33.75)
    XCTAssertEqual(param.parametricValue.value, 0.5)
  }

  func testParametricLogarithmicTransforms() {
    let ctx = Context()
    let param = ctx.params[6]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 55.648083)
    XCTAssertEqual(param.parametricValue.value, 0.5106643)
  }

  func testParametricExponentialTransforms() {
    let ctx = Context()
    let param = ctx.params[7]
    param.setParametricValue(0.5)
    XCTAssertEqual(param.value, 151.97214)
    XCTAssertEqual(param.parametricValue.value, 0.50972825)
  }

  func testObservation() {
    let ctx = Context()
    let _ = ctx.tree.token { address, value in
      XCTAssertEqual(address, 123)
      XCTAssertEqual(value, 0.5)
    }

    ctx.params[0].setValue(0.5, originator: nil)
  }

  func testObservationNonActor() async throws {
    let expectation = self.expectation(description: #function)
    let ctx = Context(expectation: expectation)
    let token = ctx.tree.token(byAddingParameterObserver: ctx.processParameter(address:value:))
    ctx.params[0].setValue(0.5, originator: nil)
    await self.fulfillment(of: [expectation])
    ctx.tree.removeParameterObserver(token)
  }

  @MainActor
  private final class MainActorContext {
    let expectation: XCTestExpectation?
    var values = [AUValue]()

    init(expectation: XCTestExpectation? = nil) {
      self.expectation = expectation
    }

    func processParameter(address: AUParameterAddress, value: AUValue) {
      print(address, value)
      if address == 123 {
        expectation?.fulfill()
        values.append(value)
        print("added")
      }
    }

    func getValues() -> [AUValue] { values }
  }

  func testObservationMainActor() async throws {
    let expectation = self.expectation(description: #function)
    let ctx = Context()
    let mac = await MainActorContext(expectation: expectation)
    let token = ctx.tree.token(byAddingParameterObserver: { address, value in
      DispatchQueue.main.async {
        mac.processParameter(address: address, value: value)
      }
    })
    ctx.params[0].setValue(0.5, originator: nil)
    await self.fulfillment(of: [expectation])
    ctx.tree.removeParameterObserver(token)
  }

  func testObservationMainActorAsyncStream() async throws {
    let expectation = self.expectation(description: #function)
    expectation.expectedFulfillmentCount = 3

    let ctx = Context()
    let mac = await MainActorContext(expectation: expectation)
    let (token, stream) = ctx.tree.parameter(withAddress: 123)!.startObserving()
    _ = Task {
      for await value in stream {
        print("new value: \(value)")
        await mac.processParameter(address: 123, value: value)
        print("sent")
      }
      print("loop done")
    }

    let pause: Duration = .milliseconds(100)
    ctx.tree.parameter(withAddress: 123)!.setValue(1.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.tree.parameter(withAddress: 123)!.setValue(2.0, originator: nil)
    try await Task.sleep(for: pause)
    ctx.tree.parameter(withAddress: 123)!.setValue(3.0, originator: nil)
    try await Task.sleep(for: pause)

    await self.fulfillment(of: [expectation], timeout: 2.0)
    ctx.tree.removeParameterObserver(token)

    let values = await mac.getValues()
    XCTAssertEqual(values, [1.0, 2.0, 3.0])
  }

  func testDynamicMemberLookup() async throws {
    let group1 = AUParameterTree.createGroup(
      withIdentifier: "group1",
      name: "Group 1",
      children: [
        AUParameterTree.createParameter(
          withIdentifier: "first",
          name: "First Name",
          address: 1001,
          min: 0.0,
          max: 100.0,
          unit: .generic,
          unitName: nil,
          flags: [.flag_IsReadable],
          valueStrings: nil,
          dependentParameters: nil
        ),
        AUParameterTree.createParameter(
          withIdentifier: "second",
          name: "Second Name",
          address: 1002,
          min: 10.0,
          max: 200.0,
          unit: .generic,
          unitName: nil,
          flags: [.flag_IsReadable],
          valueStrings: nil,
          dependentParameters: nil
        ),
      ]
    )
    let group2 = AUParameterTree.createGroup(
      withIdentifier: "group2",
      name: "Group 2",
      children: [
        AUParameterTree.createParameter(
          withIdentifier: "third",
          name: "Third Name",
          address: 2001,
          min: 0.0,
          max: 100.0,
          unit: .generic,
          unitName: nil,
          flags: [.flag_IsReadable],
          valueStrings: nil,
          dependentParameters: nil
        ),
        AUParameterTree.createParameter(
          withIdentifier: "fourth",
          name: "Fourth Name",
          address: 2002,
          min: 10.0,
          max: 200.0,
          unit: .generic,
          unitName: nil,
          flags: [.flag_IsReadable],
          valueStrings: nil,
          dependentParameters: nil
        ),
      ]
    )
    let root = AUParameterTree.createGroup(
      withIdentifier: "root",
      name: "Root",
      children: [
        group1,
        group2
      ]
    )

    let tree = AUParameterTree.createTree(withChildren: [root])
    let group = tree.dynamicMemberLookup.root?.group1
    XCTAssertNotNil(group?.group)
    XCTAssertNil(group?.parameter)

    let first = tree.dynamicMemberLookup.root?.group1?.first
    XCTAssertNotNil(first)
    var param = first?.parameter
    XCTAssertNotNil(param)
    XCTAssertEqual(param?.address, 1001)

    let second = tree.dynamicMemberLookup.root?.group1?.second
    XCTAssertNotNil(second)
    param = second?.parameter
    XCTAssertNotNil(param)
    XCTAssertEqual(param?.address, 1002)

    let third = tree.dynamicMemberLookup.root?.group2?.third
    XCTAssertNotNil(third)
    param = third?.parameter
    XCTAssertNotNil(param)
    XCTAssertEqual(param?.address, 2001)

    let fourth = tree.dynamicMemberLookup.root?.group2?.fourth
    XCTAssertNotNil(fourth)
    param = fourth?.parameter
    XCTAssertNotNil(param)
    XCTAssertEqual(param?.address, 2002)

    XCTAssertNil(fourth?.group)
    XCTAssertNil(fourth?.blahblah)

    let unknown = tree.dynamicMemberLookup.blah
    XCTAssertNil(unknown)
  }
}
