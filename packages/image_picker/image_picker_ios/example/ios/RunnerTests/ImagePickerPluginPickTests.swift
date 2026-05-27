// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import XCTest

@testable import image_picker_ios

@MainActor
class ImagePickerPluginPickTests: XCTestCase {
  func testPickImage_SetsCorrectCameraDevice() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let frontSource = SourceSpecification(type: .camera, camera: .front)
    XCTAssertEqual(plugin.cameraDevice(for: frontSource), .front)

    let rearSource = SourceSpecification(type: .camera, camera: .rear)
    XCTAssertEqual(plugin.cameraDevice(for: rearSource), .rear)
  }

  func testPickVideo_SetsCorrectDuration() {
    let mockHandler = MockDeviceCapabilityHandler()
    mockHandler.cameraAuthorizationStatusResult = .authorized
    let viewProvider = StubViewProvider(viewController: UIViewController())
    let plugin = ImagePickerPlugin(viewProvider: viewProvider, deviceCapabilityHandler: mockHandler)

    // Provide a mock picker to avoid NSInvalidArgumentException on simulators when sourceType = .camera
    plugin.setImagePickerControllerOverrides([MockUIImagePickerController()])

    plugin.pickVideo(
      source: SourceSpecification(type: .camera, camera: .rear), maxDurationSeconds: 10
    ) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxDuration, 10.0)
    XCTAssertTrue(plugin.callContext?.includeVideo ?? false)
  }

  func testPickVideo_WithZeroDuration_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickVideo(source: SourceSpecification(type: .gallery, camera: .rear), maxDurationSeconds: 0) { _ in }
    XCTAssertEqual(plugin.callContext?.maxDuration, 0.0)
  }

  func testPickVideo_WithNegativeDuration_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickVideo(source: SourceSpecification(type: .gallery, camera: .rear), maxDurationSeconds: -5) { _ in }
    XCTAssertEqual(plugin.callContext?.maxDuration, -5.0)
  }

  func testPickMultiImage_WithExtremeLimit_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickMultiImage(
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false,
      limit: Int64.max
    ) { _ in }
    XCTAssertEqual(plugin.callContext?.maxItemCount, Int.max)
  }

  func testPickMultiImage_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickMultiImage(
      maxSize: MaxSize(width: 100, height: 200), imageQuality: 50, requestFullMetadata: true,
      limit: 5
    ) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxSize?.width, 100)
    XCTAssertEqual(plugin.callContext?.maxSize?.height, 200)
    XCTAssertEqual(plugin.callContext?.imageQuality, 50)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 5)
    XCTAssertTrue(plugin.callContext?.includeImages ?? false)
    XCTAssertFalse(plugin.callContext?.includeVideo ?? true)
  }

  func testPickMultiImage_NoLimit_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickMultiImage(
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false,
      limit: nil
    ) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 0)
  }

  func testPickMedia_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let options = MediaSelectionOptions(
      maxSize: MaxSize(width: 10, height: 20),
      imageQuality: 70,
      requestFullMetadata: false,
      allowMultiple: true,
      limit: 3
    )
    plugin.pickMedia(mediaSelectionOptions: options) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxSize?.width, 10)
    XCTAssertEqual(plugin.callContext?.maxSize?.height, 20)
    XCTAssertEqual(plugin.callContext?.imageQuality, 70)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 3)
    XCTAssertTrue(plugin.callContext?.includeImages ?? false)
    XCTAssertTrue(plugin.callContext?.includeVideo ?? false)
  }

  func testPickMedia_Single_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let options = MediaSelectionOptions(
      maxSize: MaxSize(width: nil, height: nil),
      imageQuality: nil,
      requestFullMetadata: true,
      allowMultiple: false,
      limit: nil
    )
    plugin.pickMedia(mediaSelectionOptions: options) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 1)
  }

  func testPickMedia_Multiple_WithLimit_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let options = MediaSelectionOptions(
      maxSize: MaxSize(width: nil, height: nil),
      imageQuality: nil,
      requestFullMetadata: false,
      allowMultiple: true,
      limit: 10
    )
    plugin.pickMedia(mediaSelectionOptions: options) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 10)
  }

  func testPickMultiVideo_SetsCorrectContext() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    plugin.pickMultiVideo(maxDurationSeconds: 30, limit: 10) { _ in }

    XCTAssertNotNil(plugin.callContext)
    XCTAssertEqual(plugin.callContext?.maxDuration, 30.0)
    XCTAssertEqual(plugin.callContext?.maxItemCount, 10)
    XCTAssertTrue(plugin.callContext?.includeVideo ?? false)
    XCTAssertFalse(plugin.callContext?.includeImages ?? true)
  }

  func testPickImage_MultiplePaths_ReturnsError() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "Error returned for multiple paths")

    plugin.pickImage(
      source: SourceSpecification(type: .gallery, camera: .rear),
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false
    ) { result in
      if case let .failure(error as PigeonError) = result {
        XCTAssertEqual(error.code, "invalid_result")
        expectation.fulfill()
      }
    }

    plugin.sendCallResult(pathList: ["path1", "path2"])
    waitForExpectations(timeout: 1)
  }

  func testPickImage_CancelsPreviousCall() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "First call cancelled")

    plugin.pickImage(
      source: SourceSpecification(type: .gallery, camera: .rear),
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false
    ) { result in
      if case let .failure(error as PigeonError) = result {
        XCTAssertEqual(error.code, "multiple_request")
        expectation.fulfill()
      }
    }

    // This second call should trigger cancellation of the first one
    plugin.pickImage(
      source: SourceSpecification(type: .gallery, camera: .rear),
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false
    ) { _ in }

    waitForExpectations(timeout: 1)
  }

  func testPickImage_FromGallery_LaunchUIImagePickerOnOldOS() {
    let viewProvider = StubViewProvider(viewController: UIViewController())
    let plugin = ImagePickerPlugin(viewProvider: viewProvider)
    let context = ImagePickerMethodCallContext { _, _ in }
    context.includeImages = true
    plugin.setImagePickerControllerOverrides([MockUIImagePickerController()])

    plugin.pickImage(
      source: SourceSpecification(type: .gallery, camera: .rear), maxSize: MaxSize(),
      imageQuality: nil, requestFullMetadata: false
    ) { _ in }
    XCTAssertNotNil(plugin.callContext)
  }

  func testPickMultiImage_LaunchUIImagePickerOnOldOS() {
    let viewProvider = StubViewProvider(viewController: UIViewController())
    let plugin = ImagePickerPlugin(viewProvider: viewProvider)
    plugin.setImagePickerControllerOverrides([MockUIImagePickerController()])

    plugin.pickMultiImage(maxSize: MaxSize(), imageQuality: nil, requestFullMetadata: false, limit: 1) { _ in }
    XCTAssertNotNil(plugin.callContext)
  }

  func testPickMultiImage_WithNegativeLimit_DoesNotCrash() {
    if #available(iOS 14, *) {
      let viewProvider = StubViewProvider(viewController: UIViewController())
      let plugin = ImagePickerPlugin(viewProvider: viewProvider)

      let defaultSize = MaxSize(width: nil, height: nil)

      // ✅ Case 1: Negative limit (original case)
      plugin.pickMultiImage(
        maxSize: defaultSize,
        imageQuality: nil,
        requestFullMetadata: false,
        limit: -1
      ) { _ in }

      XCTAssertEqual(plugin.callContext?.maxItemCount, -1)

      // ✅ Case 2: Zero limit (edge case)
      plugin.pickMultiImage(
        maxSize: defaultSize,
        imageQuality: nil,
        requestFullMetadata: false,
        limit: 0
      ) { _ in }

      XCTAssertEqual(plugin.callContext?.maxItemCount, 0)
    }
  }

  func testPickImageMessageHandler_Success() {
    let messenger = TestBinaryMessenger()
    let viewProvider = StubViewProvider(viewController: UIViewController())
    let plugin = ImagePickerPlugin(viewProvider: viewProvider)
    ImagePickerApiSetup.setUp(binaryMessenger: messenger, api: plugin)

    let channelName = "dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickImage"
    let handler = messenger.handlers[channelName]
    XCTAssertNotNil(handler)

    let args: [Any?] = [
      SourceSpecification(type: .gallery, camera: .rear),
      MaxSize(width: 100, height: 100),
      Int64(80),
      true
    ]
    let message = MessagesPigeonCodec.shared.encode(args)

    let expectation = self.expectation(description: "Reply called")
    handler?(message) { reply in
      if let reply = reply,
        let decoded = MessagesPigeonCodec.shared.decode(reply) as? [Any?] {
        XCTAssertEqual(decoded[0] as? String, "test/path")
      } else {
        XCTFail("Reply was nil or incorrectly formatted")
      }
      expectation.fulfill()
    }

    plugin.sendCallResult(pathList: ["test/path"])
    waitForExpectations(timeout: 1)
  }
}
