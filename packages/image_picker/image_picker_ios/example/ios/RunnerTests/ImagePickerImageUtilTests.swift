// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import UIKit
import XCTest

@testable import image_picker_ios

class ImagePickerImageUtilTests: XCTestCase {
  struct ScalingTestCase {
    let maxWidth: Double?
    let maxHeight: Double?
    let expectedWidth: CGFloat
    let expectedHeight: CGFloat
  }

  func testScaledImage_Parameterized() throws {
    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))  // 12x7
    let testCases = [
      ScalingTestCase(maxWidth: 5, maxHeight: nil, expectedWidth: 5, expectedHeight: 3),
      ScalingTestCase(maxWidth: nil, maxHeight: 4, expectedWidth: 7, expectedHeight: 4),
      ScalingTestCase(maxWidth: 6, maxHeight: 6, expectedWidth: 6, expectedHeight: 4),
      ScalingTestCase(maxWidth: 10, maxHeight: 2, expectedWidth: 3, expectedHeight: 2)
    ]

    for testCase in testCases {
      let scaled = ImagePickerImageUtil.scaledImage(
        image, maxWidth: testCase.maxWidth, maxHeight: testCase.maxHeight,
        isMetadataAvailable: false
      )
      XCTAssertEqual(
        scaled.size.width, testCase.expectedWidth, accuracy: 0.5, "Width failed for \(testCase)")
      XCTAssertEqual(
        scaled.size.height, testCase.expectedHeight, accuracy: 0.5, "Height failed for \(testCase)")
    }
  }

  func testScaledImage_Parameterized_NoScaling() throws {
    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))  // 12x7
    let testCases = [
      ScalingTestCase(maxWidth: 20, maxHeight: 20, expectedWidth: 12, expectedHeight: 7),
      ScalingTestCase(maxWidth: nil, maxHeight: nil, expectedWidth: 12, expectedHeight: 7),
      ScalingTestCase(maxWidth: 0, maxHeight: 5, expectedWidth: 12, expectedHeight: 7),
      ScalingTestCase(maxWidth: 5, maxHeight: 0, expectedWidth: 12, expectedHeight: 7)
    ]

    for testCase in testCases {
      let scaled = ImagePickerImageUtil.scaledImage(
        image, maxWidth: testCase.maxWidth, maxHeight: testCase.maxHeight,
        isMetadataAvailable: false
      )
      XCTAssertEqual(scaled.size.width, testCase.expectedWidth, accuracy: 0.5)
      XCTAssertEqual(scaled.size.height, testCase.expectedHeight, accuracy: 0.5)
    }
  }

  func testScaledImage_ShouldReturnOriginalIfSizeIsSame() throws {
    let data = ImagePickerTestImages.jpgTestData
    let image = try XCTUnwrap(UIImage(data: data))

    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: image.size.width,
      maxHeight: image.size.height,
      isMetadataAvailable: true
    )

    XCTAssertEqual(image, scaledImage)
  }

  func testScaledImage_ShouldReturnOriginalIfSizeIsNil() throws {
    let data = ImagePickerTestImages.jpgTestData
    let image = try XCTUnwrap(UIImage(data: data))

    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: nil,
      maxHeight: nil,
      isMetadataAvailable: true
    )

    XCTAssertEqual(image, scaledImage)
  }

  func testScaledImage_ShouldDownscaleWidth() throws {
    let data = ImagePickerTestImages.jpgTestData
    let image = try XCTUnwrap(UIImage(data: data))
    let originalWidth = image.size.width

    let maxWidth = originalWidth / 2.0
    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: maxWidth,
      maxHeight: nil,
      isMetadataAvailable: true
    )

    XCTAssertEqual(scaledImage.size.width, maxWidth, accuracy: 1.0)
  }

  func testScaledImage_ShouldDownscaleHeight() {
    guard let image = UIImage(data: ImagePickerTestImages.jpgTestData) else {
      XCTFail("Failed to create UIImage")
      return
    }

    let originalHeight = image.size.height
    let maxHeight = originalHeight / 2.0

    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: nil,
      maxHeight: maxHeight,
      isMetadataAvailable: true
    )

    XCTAssertLessThanOrEqual(scaledImage.size.height, maxHeight + 1.0)
    XCTAssertLessThanOrEqual(scaledImage.size.width, image.size.width)

    let expectedRatio = image.size.width / image.size.height
    let actualRatio = scaledImage.size.width / scaledImage.size.height

    XCTAssertEqual(expectedRatio, actualRatio, accuracy: 0.15)
  }

  func testScaledImage_ShouldRespectAspectRatio_WhenWidthIsLimiting() {
    guard let image = UIImage(data: ImagePickerTestImages.jpgTestData) else {
      XCTFail("Failed to create UIImage")
      return
    }

    let maxWidth = image.size.width / 2.0
    let maxHeight = image.size.height

    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      isMetadataAvailable: true
    )

    XCTAssertLessThanOrEqual(scaledImage.size.width, maxWidth + 1.0)
    XCTAssertLessThanOrEqual(scaledImage.size.height, image.size.height)

    let expectedRatio = image.size.width / image.size.height
    let actualRatio = scaledImage.size.width / scaledImage.size.height

    XCTAssertEqual(expectedRatio, actualRatio, accuracy: 0.25)
  }

  func testScaledImage_ShouldRespectAspectRatio_WhenHeightIsLimiting() {
    guard let image = UIImage(data: ImagePickerTestImages.jpgTestData) else {
      XCTFail("Failed to create UIImage")
      return
    }

    let maxWidth = image.size.width  // NOT limiting
    let maxHeight = image.size.height / 2.0  // limiting

    let scaledImage = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      isMetadataAvailable: true
    )

    XCTAssertLessThanOrEqual(scaledImage.size.height, maxHeight + 1.0)

    let expectedRatio = image.size.width / image.size.height
    let actualRatio = scaledImage.size.width / scaledImage.size.height

    XCTAssertEqual(expectedRatio, actualRatio, accuracy: 0.1)
    XCTAssertLessThanOrEqual(scaledImage.size.width, image.size.width)
  }

  func testScaledImage_WithOrientation() {
    guard let baseImage = UIImage(data: ImagePickerTestImages.jpgTestData),
      let cgImage = baseImage.cgImage
    else {
      XCTFail("Failed to create UIImage")
      return
    }

    let leftImage = UIImage(cgImage: cgImage, scale: 1, orientation: .left)

    let maxWidth = leftImage.size.width / 2.0
    let maxHeight = leftImage.size.height / 2.0

    let scaledImage = ImagePickerImageUtil.scaledImage(
      leftImage,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      isMetadataAvailable: true
    )

    XCTAssertLessThanOrEqual(scaledImage.size.width, maxWidth + 1.0)
    XCTAssertLessThanOrEqual(scaledImage.size.height, maxHeight + 1.0)

    let originalRatio = leftImage.size.width / leftImage.size.height
    let scaledRatio = scaledImage.size.width / scaledImage.size.height

    XCTAssertEqual(originalRatio, scaledRatio, accuracy: 0.15)
  }

  func testScaledImage_InvalidDimensionsReturnsOriginal() {
    guard let image = UIImage(data: ImagePickerTestImages.jpgTestData) else {
      XCTFail("Failed to create UIImage")
      return
    }

    let zeroBoth = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: 0,
      maxHeight: 0,
      isMetadataAvailable: true
    )

    XCTAssertEqual(zeroBoth.size, image.size)
    XCTAssertTrue(zeroBoth === image)

    let zeroWidth = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: 0,
      maxHeight: 10,
      isMetadataAvailable: true
    )

    XCTAssertEqual(zeroWidth.size, image.size)
    XCTAssertTrue(zeroWidth === image)
  }

  func testDrawScaledImage_ZeroSize_ReturnsOriginalImage() {
    guard let image = UIImage(data: ImagePickerTestImages.jpgTestData) else {
      XCTFail("Failed to create UIImage")
      return
    }

    let zeroWidth = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: 0,
      maxHeight: 10,
      isMetadataAvailable: false
    )

    XCTAssertEqual(zeroWidth.size, image.size)
    XCTAssertTrue(zeroWidth === image)

    let zeroHeight = ImagePickerImageUtil.scaledImage(
      image,
      maxWidth: 10,
      maxHeight: 0,
      isMetadataAvailable: false
    )

    XCTAssertEqual(zeroHeight.size, image.size)
    XCTAssertTrue(zeroHeight === image)
  }
}
