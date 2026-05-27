// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import XCTest

@testable import image_picker_ios

class PigeonTests: XCTestCase {
  func testMaxSize_Equality() {
    let size1 = MaxSize(width: 100, height: 200)
    let size2 = MaxSize(width: 100, height: 200)
    let size3 = MaxSize(width: 101, height: 200)

    XCTAssertEqual(size1, size2)
    XCTAssertNotEqual(size1, size3)

    let size4 = MaxSize(width: 100, height: nil)
    let size5 = MaxSize(width: 100, height: nil)
    XCTAssertEqual(size4, size5)
    XCTAssertNotEqual(size1, size4)
  }

  func testMaxSize_Hash() {
    let size1 = MaxSize(width: 100, height: 200)
    let size2 = MaxSize(width: 100, height: 200)
    XCTAssertEqual(size1.hashValue, size2.hashValue)
  }

  func testMediaSelectionOptions_Equality() {
    let options1 = MediaSelectionOptions(
      maxSize: MaxSize(width: 10, height: 20),
      imageQuality: 80,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: 1
    )
    let options2 = MediaSelectionOptions(
      maxSize: MaxSize(width: 10, height: 20),
      imageQuality: 80,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: 1
    )
    XCTAssertEqual(options1, options2)

    var options3 = options1
    options3.imageQuality = 79
    XCTAssertNotEqual(options1, options3)

    var options4 = options1
    options4.requestFullMetadata = false
    XCTAssertNotEqual(options1, options4)
  }

  func testSourceSpecification_Equality() {
    let source1 = SourceSpecification(type: .camera, camera: .rear)
    let source2 = SourceSpecification(type: .camera, camera: .rear)
    let source3 = SourceSpecification(type: .gallery, camera: .rear)

    XCTAssertEqual(source1, source2)
    XCTAssertNotEqual(source1, source3)

    let source4 = SourceSpecification(type: .camera, camera: .front)
    XCTAssertNotEqual(source1, source4)
  }

  func testPigeonError_LocalizedDescription() {
    let error = PigeonError(code: "code", message: "msg", details: "details")
    XCTAssertTrue(error.localizedDescription.contains("code"))
    XCTAssertTrue(error.localizedDescription.contains("msg"))
    XCTAssertTrue(error.localizedDescription.contains("details"))
  }

  func testPigeonError_LocalizedDescription_NilValues() {
    let error = PigeonError(code: "code", message: nil, details: nil)
    XCTAssertTrue(error.localizedDescription.contains("<nil>"))
  }

  func testPigeonError_LocalizedDescription_WithDetails() {
    let error = PigeonError(code: "code", message: "message", details: "some details")
    XCTAssertTrue(error.localizedDescription.contains("some details"))
  }

  func testPigeonError_Equality() {
    // PigeonError doesn't implement Equatable, but we can test its properties
    let error = PigeonError(code: "a", message: "b", details: "c")
    XCTAssertEqual(error.code, "a")
    XCTAssertEqual(error.message, "b")
    XCTAssertEqual(error.details as? String, "c")
  }

  func testMaxSize_fromList_NilValues() {
    let size = MaxSize.fromList([NSNull(), NSNull()])
    XCTAssertNil(size?.width)
    XCTAssertNil(size?.height)
  }

  func testCodec() {
    let codec = MessagesPigeonCodec.shared

    // Test MaxSize
    let maxSize = MaxSize(width: 10, height: 20)
    let maxSizeData = codec.encode(maxSize)
    let decodedMaxSize = codec.decode(maxSizeData) as? MaxSize
    XCTAssertEqual(maxSize, decodedMaxSize)

    // Test MediaSelectionOptions
    let options = MediaSelectionOptions(
      maxSize: MaxSize(width: nil, height: nil),
      imageQuality: 50,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: nil
    )
    let optionsData = codec.encode(options)
    let decodedOptions = codec.decode(optionsData) as? MediaSelectionOptions
    XCTAssertEqual(options, decodedOptions)

    // Test SourceSpecification
    let source = SourceSpecification(type: .gallery, camera: .front)
    let sourceData = codec.encode(source)
    let decodedSource = codec.decode(sourceData) as? SourceSpecification
    XCTAssertEqual(source, decodedSource)

    // Test Enums
    XCTAssertEqual(codec.decode(codec.encode(SourceCamera.front)) as? SourceCamera, .front)
    XCTAssertEqual(codec.decode(codec.encode(SourceType.gallery)) as? SourceType, .gallery)
    XCTAssertEqual(codec.decode(codec.encode(SourceCamera.rear)) as? SourceCamera, .rear)
    XCTAssertEqual(codec.decode(codec.encode(SourceType.camera)) as? SourceType, .camera)

    // Test Nil Enums
    let nilCamera: SourceCamera? = nil
    XCTAssertNil(codec.decode(codec.encode(nilCamera as Any)))

    // Test CoverageModel
    let coverage = CoverageModel(list: ["a", 1], map: ["k": "v"])
    XCTAssertEqual(coverage, codec.decode(codec.encode(coverage)) as? CoverageModel)
  }

  func testModelsFromList() {
    XCTAssertEqual(MaxSize.fromList([10.0, 20.0]), MaxSize(width: 10, height: 20))
    XCTAssertEqual(
      SourceSpecification.fromList([SourceType.camera.rawValue, SourceCamera.front.rawValue]),
      SourceSpecification(type: .camera, camera: .front)
    )

    let options = MediaSelectionOptions(
      maxSize: MaxSize(width: 10, height: 20),
      imageQuality: 50,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: 5
    )
    let optionsList: [Any?] = [
      options.maxSize,
      options.imageQuality,
      options.requestFullMetadata,
      options.allowMultiple,
      options.limit
    ]
    XCTAssertEqual(MediaSelectionOptions.fromList(optionsList), options)
  }

  func testSourceSpecification_fromList() {
    let source = SourceSpecification(type: .gallery, camera: .front)
    let list: [Any?] = [SourceType.gallery.rawValue, SourceCamera.front.rawValue]
    XCTAssertEqual(SourceSpecification.fromList(list), source)
  }

  func testPigeonCodec_UnknownType() {
    let reader = MessagesPigeonCodec.shared.makeReader(for: Data([200]))  // 200 is an unknown type
    XCTAssertNil(reader.readValue())
  }

  func testPigeonError_LocalizedDescription_Full() {
    let error = PigeonError(code: "C", message: "M", details: "D")
    XCTAssertEqual(error.localizedDescription, "PigeonError(code: C, message: M, details: D)")
  }

  func testModels_toList() {
    let size = MaxSize(width: 1.0, height: 2.0)
    XCTAssertEqual(size.toList()[0] as? Double, 1.0)
    XCTAssertEqual(size.toList()[1] as? Double, 2.0)

    let source = SourceSpecification(type: .camera, camera: .front)
    XCTAssertEqual(source.toList()[0] as? Int, SourceType.camera.rawValue)
    XCTAssertEqual(source.toList()[1] as? Int, SourceCamera.front.rawValue)

    let options = MediaSelectionOptions(
      maxSize: size,
      imageQuality: 50,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: 1
    )
    let list = options.toList()
    XCTAssertEqual(list.count, 5)
  }
}
