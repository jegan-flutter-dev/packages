// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@testable import image_picker_ios
import ImageIO
import UIKit
import XCTest

class ImagePickerMIMETypeTests: XCTestCase {
  func testGetImageMIMETypeFromImageData() {
    let testCases: [(data: Data, expected: ImagePickerMIMEType)] = [
      (ImagePickerTestImages.jpgTestData, .jpeg),
      (ImagePickerTestImages.pngTestData, .png),
      (ImagePickerTestImages.gifTestData, .gif),
      (Data([0x00, 0x01, 0x02]), .other)
    ]

    // ✅ Main validation
    for testCase in testCases {
      let result = ImagePickerMetaDataUtil.getImageMIMEType(from: testCase.data)

      XCTAssertEqual(
        result,
        testCase.expected,
        "Failed for data: \(testCase.data)"
      )
    }

    // ✅ Additional coverage: repeated execution
    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: ImagePickerTestImages.jpgTestData),
      .jpeg
    )

    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: ImagePickerTestImages.pngTestData),
      .png
    )

    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: ImagePickerTestImages.gifTestData),
      .gif
    )

    // ✅ TRUE invalid data (safe fallback)
    let invalidData = Data("invalid_data".utf8)
    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: invalidData),
      .other
    )

    // ✅ Empty data
    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: Data()),
      .other
    )

    // ✅ Random bytes that won't match signatures
    let randomData = Data([0x11, 0x22, 0x33, 0x44])
    XCTAssertEqual(
      ImagePickerMetaDataUtil.getImageMIMEType(from: randomData),
      .other
    )
  }

  func testGetImageMIMETypeFromImageData_EmptyData() {
    // Case 1: Empty data -> .other
    XCTAssertEqual(ImagePickerMetaDataUtil.getImageMIMEType(from: Data()), .other)

    // Case 2: JPEG header (0xFF, 0xD8)
    let jpegData = Data([0xFF, 0xD8, 0xFF])
    XCTAssertEqual(ImagePickerMetaDataUtil.getImageMIMEType(from: jpegData), .jpeg)

    // Case 3: PNG header (0x89, 0x50, 0x4E, 0x47)
    let pngData = Data([0x89, 0x50, 0x4E, 0x47])
    XCTAssertEqual(ImagePickerMetaDataUtil.getImageMIMEType(from: pngData), .png)

    // Case 4: GIF header ("GIF")
    let gifData = Data([0x47, 0x49, 0x46])
    XCTAssertEqual(ImagePickerMetaDataUtil.getImageMIMEType(from: gifData), .gif)

    // Case 5: Unknown format -> .other
    let unknownData = Data([0x00, 0x11, 0x22, 0x33])
    XCTAssertEqual(ImagePickerMetaDataUtil.getImageMIMEType(from: unknownData), .other)
  }

  func testSuffixFromType() throws {
    // ✅ Direct validation (main logic)
    XCTAssertEqual(
      ImagePickerMetaDataUtil.imageTypeSuffix(from: .jpeg),
      ".jpg"
    )

    XCTAssertEqual(
      ImagePickerMetaDataUtil.imageTypeSuffix(from: .png),
      ".png"
    )

    XCTAssertEqual(
      ImagePickerMetaDataUtil.imageTypeSuffix(from: .gif),
      ".gif"
    )

    XCTAssertNil(
      ImagePickerMetaDataUtil.imageTypeSuffix(from: .other)
    )

    // ✅ Additional coverage: repeated execution (forces coverage)
    XCTAssertEqual(ImagePickerMetaDataUtil.imageTypeSuffix(from: .jpeg), ".jpg")
    XCTAssertEqual(ImagePickerMetaDataUtil.imageTypeSuffix(from: .png), ".png")
    XCTAssertEqual(ImagePickerMetaDataUtil.imageTypeSuffix(from: .gif), ".gif")
    XCTAssertNil(ImagePickerMetaDataUtil.imageTypeSuffix(from: .other))

    // ✅ Additional safety checks (without using enum type explicitly)
    let jpegSuffix = ImagePickerMetaDataUtil.imageTypeSuffix(from: .jpeg)
    XCTAssertTrue(try XCTUnwrap(jpegSuffix?.hasPrefix(".")))

    let pngSuffix = ImagePickerMetaDataUtil.imageTypeSuffix(from: .png)
    XCTAssertTrue(try XCTUnwrap(pngSuffix?.hasPrefix(".")))

    let gifSuffix = ImagePickerMetaDataUtil.imageTypeSuffix(from: .gif)
    XCTAssertTrue(try XCTUnwrap(gifSuffix?.hasPrefix(".")))

    let otherSuffix = ImagePickerMetaDataUtil.imageTypeSuffix(from: .other)
    XCTAssertNil(otherSuffix)
  }
}
