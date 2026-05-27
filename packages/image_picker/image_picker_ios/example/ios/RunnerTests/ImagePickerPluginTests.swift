// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import XCTest

@testable import image_picker_ios

@MainActor
class ImagePickerPluginTests: XCTestCase {
  func testPluginRegistration() {
    let registrar = TestPluginRegistrar()
    ImagePickerPlugin.register(with: registrar)
    XCTAssertNotNil(registrar.publishedInstance)
    XCTAssertTrue(registrar.publishedInstance is ImagePickerPlugin)
  }

  func testInit_DefaultHandler() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    XCTAssertTrue(plugin.deviceCapabilityHandler is DefaultDeviceCapabilityHandler)
  }

  func testCreateImagePickerController_ConfiguredCorrectly() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let picker = plugin.createImagePickerController()

    XCTAssertNotNil(picker)
  }

  func testCreateImagePickerController_WithOverrides() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let mockPicker = MockUIImagePickerController()
    plugin.setImagePickerControllerOverrides([mockPicker])

    let picker = plugin.createImagePickerController()
    XCTAssertEqual(picker, mockPicker)

    // After one use, it should fall back to creating a new one
    let secondPicker = plugin.createImagePickerController()
    XCTAssertNotEqual(secondPicker, mockPicker)
  }

  func testApiSetup_SetsHandlers() {
    let messenger = TestBinaryMessenger()
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    ImagePickerApiSetup.setUp(binaryMessenger: messenger, api: plugin)

    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickImage"])
    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickMultiImage"])
    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickVideo"])
    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickMultiVideo"])
    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickMedia"])
  }

  func testApiSetup_ClearsHandlers() {
    let messenger = TestBinaryMessenger()
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    ImagePickerApiSetup.setUp(binaryMessenger: messenger, api: plugin)
    ImagePickerApiSetup.setUp(binaryMessenger: messenger, api: nil)

    XCTAssertTrue(messenger.handlers.isEmpty)
  }

  func testApiSetup_WithSuffix() {
    let messenger = TestBinaryMessenger()
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    ImagePickerApiSetup.setUp(
      binaryMessenger: messenger, api: plugin, messageChannelSuffix: "testSuffix")

    XCTAssertNotNil(
      messenger.handlers["dev.flutter.pigeon.image_picker_ios.ImagePickerApi.pickImage.testSuffix"])
  }

  func testCancelInProgressCall_SendsError() {
    let expectation = self.expectation(description: "Previous call returns error")
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())

    plugin.callContext = ImagePickerMethodCallContext { _, error in
      if let error = error as? PigeonError {
        XCTAssertEqual(error.code, "multiple_request")
        expectation.fulfill()
      }
    }

    plugin.pickImage(
      source: SourceSpecification(type: .gallery, camera: .rear),
      maxSize: MaxSize(width: nil, height: nil), imageQuality: nil, requestFullMetadata: false
    ) { _ in }

    waitForExpectations(timeout: 1)
  }

  func testGetDesiredImageQuality() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let testCases: [(input: Double?, expected: Double)] = [
      (nil, 1.0),
      (100.0, 1.0),
      (50.0, 0.5),
      (0.0, 0.0),
      (-1.0, 1.0),
      (101.0, 1.0),
      (-100.0, 1.0),
      (1000.0, 1.0)
    ]

    for testCase in testCases {
      XCTAssertEqual(
        plugin.getDesiredImageQuality(testCase.input),
        testCase.expected,
        "Failed for input: \(String(describing: testCase.input))"
      )
    }
  }

  func testRemoveInteractionBlocker_WhenNil_DoesNotCrash() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())

    plugin.interactionBlockerWindow = nil
    plugin.previousKeyWindow = nil

    plugin.removeInteractionBlocker()
    XCTAssertNil(plugin.interactionBlockerWindow)
  }
}
