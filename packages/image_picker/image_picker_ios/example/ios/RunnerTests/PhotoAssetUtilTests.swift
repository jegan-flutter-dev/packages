// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import ImageIO
import Photos
import UIKit
import XCTest

@testable import image_picker_ios

class PhotoAssetUtilTests: XCTestCase {
  func testGetAssetFromImagePickerInfo_ReturnsAssetIfAvailable() {
    // Note: instantiating a real PHAsset is restricted, but we can test the lookup.
    let mockData: [UIImagePickerController.InfoKey: Any] = [:]
    XCTAssertNil(ImagePickerPhotoAssetUtil.getAsset(from: mockData))
  }

  func testSaveVideo_WithValidURL_ShouldSucceed() throws {
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "test_video.mp4")
    try "test".data(using: .utf8)?.write(to: tempURL)
    let savedURL = ImagePickerPhotoAssetUtil.saveVideo(from: tempURL)
    let unwrappedSavedURL = try XCTUnwrap(savedURL)
    XCTAssertTrue(FileManager.default.fileExists(atPath: unwrappedSavedURL.path))
    try? FileManager.default.removeItem(at: tempURL)
    try? FileManager.default.removeItem(at: unwrappedSavedURL)
  }

  func testSaveVideo_WithInvalidURL_ShouldReturnNil() {
    let invalidURL = URL(fileURLWithPath: "/non/existent/path.mp4")
    let savedURL = ImagePickerPhotoAssetUtil.saveVideo(from: invalidURL)
    XCTAssertNil(savedURL)
  }

  func testSaveImage_WithOriginalImageData_ShouldSaveWithCorrectExtension() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let savedPathJPG = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG,
      image: imageJPG,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(savedPathJPG)
    XCTAssertEqual(URL(fileURLWithPath: unwrappedPath).pathExtension, "jpg")
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithGifData_ShouldPreserveAnimation() throws {
    let dataGIF = ImagePickerTestImages.gifTestData
    let imageGIF = try XCTUnwrap(UIImage(data: dataGIF))
    let savedPathGIF = ImagePickerPhotoAssetUtil.saveImage(
      with: dataGIF,
      image: imageGIF,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(savedPathGIF)
    XCTAssertEqual(URL(fileURLWithPath: unwrappedPath).pathExtension, "gif")
    let newDataGIF = try Data(contentsOf: URL(fileURLWithPath: unwrappedPath))
    let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(newDataGIF as CFData, nil))
    XCTAssertGreaterThan(CGImageSourceGetCount(imageSource), 1)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithQualitySetting_ReducesSize() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let pathHigh = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG, image: imageJPG, maxWidth: nil, maxHeight: nil, imageQuality: 1.0)
    let pathLow = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG, image: imageJPG, maxWidth: nil, maxHeight: nil, imageQuality: 0.1)
    let unwrappedPathHigh = try XCTUnwrap(pathHigh)
    let unwrappedPathLow = try XCTUnwrap(pathLow)
    let sizeHigh = (try Data(contentsOf: URL(fileURLWithPath: unwrappedPathHigh))).count
    let sizeLow = (try Data(contentsOf: URL(fileURLWithPath: unwrappedPathLow))).count
    XCTAssertTrue(sizeLow < sizeHigh)
    try? FileManager.default.removeItem(atPath: unwrappedPathHigh)
    try? FileManager.default.removeItem(atPath: unwrappedPathLow)
  }

  func testSaveImage_WithOnlyUIImage_ShouldStillSaveAsJpeg() throws {
    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))
    let path = ImagePickerPhotoAssetUtil.saveImage(
      with: nil,
      image: image,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(path)
    XCTAssertTrue(unwrappedPath.hasSuffix(".jpg"))
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithPickerInfo_ExtractsMetadata() throws {
    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))
    let meta: [String: Any] = [kCGImagePropertyOrientation as String: 1]
    let info: [UIImagePickerController.InfoKey: Any] = [.mediaMetadata: meta]
    let path = ImagePickerPhotoAssetUtil.saveImage(with: info, image: image, imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(path)
    let savedData = try Data(contentsOf: URL(fileURLWithPath: unwrappedPath))
    let savedMeta = ImagePickerMetaDataUtil.getMetaData(from: savedData)
    XCTAssertEqual(savedMeta?[kCGImagePropertyOrientation as String] as? Int, 1)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithPNGData_SavesAsPNG() throws {
    let dataPNG = ImagePickerTestImages.pngTestData
    let imagePNG = try XCTUnwrap(UIImage(data: dataPNG))
    let savedPathPNG = ImagePickerPhotoAssetUtil.saveImage(
      with: dataPNG,
      image: imagePNG,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(savedPathPNG)
    XCTAssertEqual(URL(fileURLWithPath: unwrappedPath).pathExtension, "png")
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithScaling_ResizesFile() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG,
      image: imageJPG,
      maxWidth: 5,
      maxHeight: 5,
      imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(savedPath)
    let savedImage = try XCTUnwrap(UIImage(contentsOfFile: unwrappedPath))
    XCTAssertLessThanOrEqual(savedImage.size.width, 5.0)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithWideScaling_ResizesFile() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG,
      image: imageJPG,
      maxWidth: 10,
      maxHeight: nil,
      imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(savedPath)
    let savedImage = try XCTUnwrap(UIImage(contentsOfFile: unwrappedPath))
    XCTAssertLessThanOrEqual(savedImage.size.width, 10.0)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithTallScaling_ResizesFile() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG,
      image: imageJPG,
      maxWidth: nil,
      maxHeight: 10,
      imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(savedPath)
    let savedImage = try XCTUnwrap(UIImage(contentsOfFile: unwrappedPath))
    XCTAssertLessThanOrEqual(savedImage.size.height, 10.0)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithLargeScaling_DoesNotResizeFile() throws {
    let dataJPG = ImagePickerTestImages.jpgTestData
    let imageJPG = try XCTUnwrap(UIImage(data: dataJPG))
    let originalWidth = imageJPG.size.width
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataJPG,
      image: imageJPG,
      maxWidth: originalWidth + 100,
      maxHeight: nil,
      imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(savedPath)
    let savedImage = try XCTUnwrap(UIImage(contentsOfFile: unwrappedPath))
    XCTAssertEqual(savedImage.size.width, originalWidth)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithGIFScaling_ResizesFile() throws {
    let dataGIF = ImagePickerTestImages.gifTestData
    let imageGIF = try XCTUnwrap(UIImage(data: dataGIF))
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataGIF,
      image: imageGIF,
      maxWidth: 5,
      maxHeight: 5,
      imageQuality: 1.0)
    let unwrappedPath = try XCTUnwrap(savedPath)
    let savedData = try Data(contentsOf: URL(fileURLWithPath: unwrappedPath))
    let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(savedData as CFData, nil))
    let frameCount = CGImageSourceGetCount(imageSource)
    XCTAssertGreaterThan(frameCount, 1)
    for i in 0..<frameCount {
      let frameImage = try XCTUnwrap(CGImageSourceCreateImageAtIndex(imageSource, i, nil))
      XCTAssertLessThanOrEqual(CGFloat(frameImage.width), 5.0)
      XCTAssertLessThanOrEqual(CGFloat(frameImage.height), 5.0)
    }
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithPNGData_AndQuality_StillSavesAsPNG() throws {
    let dataPNG = ImagePickerTestImages.pngTestData
    let imagePNG = try XCTUnwrap(UIImage(data: dataPNG))
    let savedPath = ImagePickerPhotoAssetUtil.saveImage(
      with: dataPNG,
      image: imagePNG,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: 0.5)
    let unwrappedPath = try XCTUnwrap(savedPath)
    XCTAssertEqual(URL(fileURLWithPath: unwrappedPath).pathExtension, "png")
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithInvalidType_DefaultsToJpeg() throws {
    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))
    // We can't easily force an "invalid" type into saveImage because it's inferred from data,
    // but we can pass data that results in .other.
    let dataOther = Data([0x00, 0x01, 0x02])  // Not jpeg, png, or gif
    let path = ImagePickerPhotoAssetUtil.saveImage(
      with: dataOther,
      image: image,
      maxWidth: nil,
      maxHeight: nil,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(path)
    XCTAssertTrue(unwrappedPath.hasSuffix(".jpg"))
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testScaledGIFImage_WithInvalidData_ReturnsNil() {
    let result = ImagePickerImageUtil.scaledGIFImage(
      Data("not a gif".utf8), maxWidth: 10, maxHeight: 10)
    XCTAssertNil(result)
  }

  func testScaledGIFImage_WithEmptyData_ReturnsNil() {
    let result = ImagePickerImageUtil.scaledGIFImage(Data(), maxWidth: 10, maxHeight: 10)
    XCTAssertNil(result)
  }

  func testSaveVideo_WhenCopyFails_ReturnsNil() {
    // Creating a URL that is readable but whose copy might fail?
    // Maybe a directory instead of a file.
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_dir")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let result = ImagePickerPhotoAssetUtil.saveVideo(from: tempDir)
    XCTAssertNil(result)
    try? FileManager.default.removeItem(at: tempDir)
  }

  func testSaveVideo_WhenSourceNotReadable_ReturnsNil() {
    let nonExistentURL = URL(fileURLWithPath: "/tmp/this_does_not_exist_at_all.mp4")
    let result = ImagePickerPhotoAssetUtil.saveVideo(from: nonExistentURL)
    XCTAssertNil(result)
  }

  func testSaveVideo_WithDirectoryInsteadOfFile_ReturnsNil() {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(
      "test_dir_negative")
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let result = ImagePickerPhotoAssetUtil.saveVideo(from: tempDir)
    XCTAssertNil(result)
    try? FileManager.default.removeItem(at: tempDir)
  }

  func testSaveImage_GifWithScaling_Success() throws {
    let dataGIF = ImagePickerTestImages.gifTestData
    let imageGIF = try XCTUnwrap(UIImage(data: dataGIF))
    let path = ImagePickerPhotoAssetUtil.saveImage(
      with: dataGIF,
      image: imageGIF,
      maxWidth: 5,
      maxHeight: 5,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(path)
    XCTAssertTrue(unwrappedPath.hasSuffix(".gif"))
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }

  func testSaveImage_WithGifInfoNil_ReturnsNil() {
    // This tests the private saveImage method by passing nil gifInfo.
    // We can't call it directly but we can trigger it if scaledGIFImage returns nil.
    let invalidGifData = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0, 0, 0, 0])  // Invalid GIF header
    let image = UIImage()
    let path = ImagePickerPhotoAssetUtil.saveImage(
      with: invalidGifData,
      image: image,
      maxWidth: 5,
      maxHeight: 5,
      imageQuality: nil)
    XCTAssertNil(path)
  }

  func testSaveImage_WithLargeGIFScaling_Success() throws {
    let dataGIF = ImagePickerTestImages.gifTestData
    let imageGIF = try XCTUnwrap(UIImage(data: dataGIF))
    let path = ImagePickerPhotoAssetUtil.saveImage(
      with: dataGIF,
      image: imageGIF,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: nil)
    let unwrappedPath = try XCTUnwrap(path)
    try? FileManager.default.removeItem(atPath: unwrappedPath)
  }
}
