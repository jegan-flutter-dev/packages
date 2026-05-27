// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest

@testable import image_picker_ios

class ImagePickerGIFUtilTests: XCTestCase {
  func testScaledGIFImage_ShouldMaintainFrameCount() {
    let data = ImagePickerTestImages.gifTestData

    // ✅ Case 1: Main scaling scenario
    let info = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: 5,
      maxHeight: 5
    )

    XCTAssertNotNil(info)
    XCTAssertEqual(info?.images.count, 3)
    XCTAssertGreaterThan(info?.interval ?? 0, 0)

    if let images = info?.images {
      for image in images {
        XCTAssertLessThanOrEqual(image.size.width, 5)
        XCTAssertLessThanOrEqual(image.size.height, 5)
      }
    }

    // ✅ Case 2: No scaling (nil constraints)
    let noScaleInfo = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: nil,
      maxHeight: nil
    )

    XCTAssertNotNil(noScaleInfo)
    XCTAssertEqual(noScaleInfo?.images.count, 3)
  }

  func testScaledGIFImage_AdditionalScaling() {
    let data = ImagePickerTestImages.gifTestData

    // ✅ Case 3: Width-only scaling
    let widthOnly = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: 4,
      maxHeight: nil
    )

    XCTAssertNotNil(widthOnly)
    XCTAssertEqual(widthOnly?.images.count, 3)

    // ✅ Case 4: Height-only scaling
    let heightOnly = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: nil,
      maxHeight: 4
    )

    XCTAssertNotNil(heightOnly)
    XCTAssertEqual(heightOnly?.images.count, 3)
  }

  func testScaledGIFImage_InvalidDataReturnsNil() {
    let stringData = Data("Not a gif".utf8)
    let result = ImagePickerImageUtil.scaledGIFImage(
      stringData,
      maxWidth: 5,
      maxHeight: 5
    )
    XCTAssertNil(result)

    let emptyData = Data()
    let resultEmpty = ImagePickerImageUtil.scaledGIFImage(
      emptyData,
      maxWidth: nil,
      maxHeight: nil
    )
    XCTAssertNil(resultEmpty)

    let randomData = Data([0x01, 0x02, 0x03, 0x04])
    let resultRandom = ImagePickerImageUtil.scaledGIFImage(
      randomData,
      maxWidth: 3,
      maxHeight: 3
    )
    XCTAssertNil(resultRandom)
  }

  func testScaledGIFImage_EdgeCases() {
    let data = ImagePickerTestImages.gifTestData

    // ✅ Case: Corrupted GIF-like header
    let fakeGIFHeader = Data([0x47, 0x49, 0x46, 0x00])  // "GIF" + invalid
    let result = ImagePickerImageUtil.scaledGIFImage(
      fakeGIFHeader,
      maxWidth: 10,
      maxHeight: 10
    )
    XCTAssertNil(result)

    // ✅ Case: Repeated execution
    let repeated = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: 5,
      maxHeight: 5
    )
    XCTAssertNotNil(repeated)
  }

  func testScaledGIFImage_ShouldHandleNoDelayInfo() {
    let data = ImagePickerTestImages.gifTestData

    let info = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: nil,
      maxHeight: nil
    )

    XCTAssertNotNil(info)
    XCTAssertGreaterThan(info?.interval ?? 0, 0)

    let scaledInfo = ImagePickerImageUtil.scaledGIFImage(
      data,
      maxWidth: 3,
      maxHeight: 2
    )

    XCTAssertNotNil(scaledInfo)
    if let images = scaledInfo?.images {
      for image in images {
        XCTAssertLessThanOrEqual(image.size.width, 3.1)
        XCTAssertLessThanOrEqual(image.size.height, 2.1)
      }
    }
  }

  func testScaledGIFImage_EmptyData_ReturnsNil() {
    XCTAssertNil(
      ImagePickerImageUtil.scaledGIFImage(
        Data(),
        maxWidth: nil,
        maxHeight: nil
      ))

    XCTAssertNil(
      ImagePickerImageUtil.scaledGIFImage(
        Data(),
        maxWidth: 3,
        maxHeight: 2
      ))
  }
}
