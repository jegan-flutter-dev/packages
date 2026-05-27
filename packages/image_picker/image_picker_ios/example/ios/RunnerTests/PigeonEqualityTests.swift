// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import XCTest

@testable import image_picker_ios

class PigeonEqualityTests: XCTestCase {
  func testDeepEqualsMessages() {
    XCTAssertTrue(deepEqualsMessages(nil, nil))
    XCTAssertFalse(deepEqualsMessages(1, nil))
    XCTAssertFalse(deepEqualsMessages(nil, 1))
    XCTAssertTrue(deepEqualsMessages([1, 2], [1, 2]))
    XCTAssertFalse(deepEqualsMessages([1, 2], [1, 3]))
    XCTAssertFalse(deepEqualsMessages([1, 2], [1]))
    XCTAssertTrue(deepEqualsMessages(["a": 1], ["a": 1]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["a": 2]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["b": 1]))
    XCTAssertFalse(deepEqualsMessages(["a": 1, "b": 2], ["a": 1]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["a": 1, "b": 2]))
    XCTAssertTrue(deepEqualsMessages(1.0, 1.0))
    XCTAssertTrue(deepEqualsMessages(Double.nan, Double.nan))
    XCTAssertTrue(deepEqualsMessages([1.0, 2.0] as [Double], [1.0, 2.0] as [Double]))
    XCTAssertFalse(deepEqualsMessages([1.0, 2.0] as [Double], [1.0, 3.0] as [Double]))
    XCTAssertFalse(deepEqualsMessages([1.0, 2.0] as [Double], [1.0] as [Double]))
    XCTAssertFalse(deepEqualsMessages([1.0] as [Double], [1.0, 2.0] as [Double]))
    XCTAssertFalse(deepEqualsMessages([1.0] as [Double], [1]))

    // Identity check
    let obj = NSObject()
    XCTAssertTrue(deepEqualsMessages(obj, obj))

    // Void check
    XCTAssertTrue(deepEqualsMessages((), ()))
    XCTAssertFalse(deepEqualsMessages((), 1))

    // Double Array check
    let doubles1: [Double] = [1.1, 2.2]
    let doubles2: [Double] = [1.1, 2.2]
    let doubles3: [Double] = [1.1, 2.3]
    XCTAssertTrue(deepEqualsMessages(doubles1, doubles2))
    XCTAssertFalse(deepEqualsMessages(doubles1, doubles3))
    XCTAssertFalse(deepEqualsMessages(doubles1, [1.1]))

    // Mixed types
    XCTAssertFalse(deepEqualsMessages([1], ["1"]))

    // Nested mixed types
    XCTAssertTrue(deepEqualsMessages(["a": [1, 2]], ["a": [1, 2]]))
    XCTAssertFalse(deepEqualsMessages(["a": [1, 2]], ["a": [1, 3]]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["a": 2]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["b": 1]))
    XCTAssertFalse(deepEqualsMessages(["a": 1], ["a": 1, "b": 2]))
    XCTAssertFalse(deepEqualsMessages(["a": 1, "b": 2], ["c": 1, "d": 2]))
    XCTAssertFalse(deepEqualsMessages(["a": 1, "b": 2], ["a": 1, "c": 2]))
    XCTAssertFalse(deepEqualsMessages(["a": 1, "b": 2], ["a": 2, "b": 1]))

    // AnyHashable
    XCTAssertTrue(deepEqualsMessages("test" as AnyHashable, "test" as AnyHashable))
    XCTAssertFalse(deepEqualsMessages("test" as AnyHashable, "other" as AnyHashable))

    // Mixed lists
    XCTAssertFalse(deepEqualsMessages([1.0] as [Double], [1.0] as [Any?]))
    XCTAssertFalse(deepEqualsMessages([1.0] as [Any?], [1.0] as [Double]))
  }

  func testDeepHashMessages() {
    var hasher1 = Hasher()
    deepHashMessages(value: ["a": [1, 2, ["b": 3.3]]], hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: ["a": [1, 2, ["b": 3.3]]], hasher: &hasher2)

    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())

    var hasherA = Hasher()
    deepHashMessages(value: ["a": 1], hasher: &hasherA)

    var hasherB = Hasher()
    deepHashMessages(value: ["a": 1], hasher: &hasherB)

    XCTAssertEqual(hasherA.finalize(), hasherB.finalize())

    var hasherC = Hasher()
    deepHashMessages(value: ["a": 1, "b": 2], hasher: &hasherC)
    XCTAssertNotEqual(hasherA.finalize(), hasherC.finalize())
  }

  func testDeepHashMessages_List() {
    var hasher1 = Hasher()
    deepHashMessages(value: [1, 2], hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: [1, 2], hasher: &hasher2)

    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
  }

  func testDeepHashMessages_Doubles() {
    var hasher1 = Hasher()
    deepHashMessages(value: 1.0, hasher: &hasher1)
    var hasher2 = Hasher()
    deepHashMessages(value: 1.0, hasher: &hasher2)
    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())

    var hasher3 = Hasher()
    deepHashMessages(value: Double.nan, hasher: &hasher3)
    var hasher4 = Hasher()
    deepHashMessages(value: Double.nan, hasher: &hasher4)
    XCTAssertEqual(hasher3.finalize(), hasher4.finalize())

    var hasher5 = Hasher()
    deepHashMessages(value: 0.0, hasher: &hasher5)
    var hasher6 = Hasher()
    deepHashMessages(value: -0.0, hasher: &hasher6)
    XCTAssertEqual(hasher5.finalize(), hasher6.finalize())
  }

  func testDeepHashMessages_DoubleArray() {
    var hasher1 = Hasher()
    deepHashMessages(value: [1.0, 2.0] as [Double], hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: [1.0, 2.0] as [Double], hasher: &hasher2)

    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())

    var hasher3 = Hasher()
    deepHashMessages(value: [1.0, 3.0] as [Double], hasher: &hasher3)
    XCTAssertNotEqual(hasher1.finalize(), hasher3.finalize())
  }

  func testDeepHashMessages_Dictionary() {
    var hasher1 = Hasher()
    deepHashMessages(value: ["a": 1, "b": 2], hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: ["b": 2, "a": 1], hasher: &hasher2)

    // Order shouldn't matter for dictionary hashing in Pigeon
    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
  }

  func testDeepHashMessages_UnhandledType() {
    let obj = NSObject()
    var hasher1 = Hasher()
    deepHashMessages(value: obj, hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: obj, hasher: &hasher2)

    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())

    // Different objects should ideally have different hashes
    var hasher3 = Hasher()
    deepHashMessages(value: NSObject(), hasher: &hasher3)
    // Not strictly guaranteed, but likely
    XCTAssertNotEqual(hasher1.finalize(), hasher3.finalize())
  }

  func testDeepHashMessages_Nil() {
    var hasher1 = Hasher()
    deepHashMessages(value: nil, hasher: &hasher1)

    var hasher2 = Hasher()
    deepHashMessages(value: NSNull(), hasher: &hasher2)

    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
  }

  func testDeepEquals_DifferentTypes() {
    XCTAssertFalse(deepEqualsMessages(1, "1"))
    XCTAssertFalse(deepEqualsMessages([1], 1))
    XCTAssertFalse(deepEqualsMessages(["a": 1], [1]))
  }

  func testDeepEquals_NaN() {
    XCTAssertTrue(deepEqualsMessages(Double.nan, Double.nan))
    XCTAssertFalse(deepEqualsMessages(Double.nan, 1.0))
  }

  func testDeepEquals_Void() {
    XCTAssertTrue(deepEqualsMessages((), ()))
  }

  func testDeepEquals_DoubleArray() {
    let doubles1: [Double] = [1.0, 2.0]
    let doubles2: [Double] = [1.0, 2.0]
    let doubles3: [Double] = [1.0, 3.0]
    XCTAssertTrue(deepEqualsMessages(doubles1, doubles2))
    XCTAssertFalse(deepEqualsMessages(doubles1, doubles3))
    XCTAssertFalse(deepEqualsMessages(doubles1, [1.0]))
  }

  func testDeepHash_DoubleArray() {
    var hasher1 = Hasher()
    deepHashMessages(value: [1.0, 2.0] as [Double], hasher: &hasher1)
    var hasher2 = Hasher()
    deepHashMessages(value: [1.0, 2.0] as [Double], hasher: &hasher2)
    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
  }

  func testDeepHash_ComplexDictionary() {
    var hasher1 = Hasher()
    deepHashMessages(value: ["a": 1, 2: "b"], hasher: &hasher1)
    var hasher2 = Hasher()
    deepHashMessages(value: [2: "b", "a": 1], hasher: &hasher2)
    XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
  }

  func testCoverageModel_DeepEquals() {
    let model1 = CoverageModel(list: [1], map: ["a": 1])
    let model2 = CoverageModel(list: [1], map: ["a": 1])
    XCTAssertEqual(model1, model2)

    let model3 = CoverageModel(list: [2], map: ["a": 1])
    XCTAssertNotEqual(model1, model3)
  }
}
