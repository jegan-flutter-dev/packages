// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import XCTest

@testable import image_picker_ios

@MainActor
class ImagePickerPluginAuthorizationTests: XCTestCase {

  func testCheckCameraAuthorization_NotDetermined_Granted() {
    let mockHandler = MockDeviceCapabilityHandler()
    mockHandler.cameraAuthorizationStatusResult = .notDetermined
    mockHandler.requestCameraAccessResult = true
    let plugin = ImagePickerPlugin(
      viewProvider: StubViewProvider(viewController: UIViewController()),
      deviceCapabilityHandler: mockHandler)

    plugin.callContext = ImagePickerMethodCallContext { _, _ in }
    plugin.checkCameraAuthorization(with: UIImagePickerController(), camera: .rear)

    XCTAssertTrue(mockHandler.requestCameraAccessCalled)
  }

  func testCheckCameraAuthorization_HandlesAllStatuses() {
    let mockHandler = MockDeviceCapabilityHandler()
    let viewProvider = StubViewProvider(viewController: UIViewController())
    let plugin = ImagePickerPlugin(viewProvider: viewProvider, deviceCapabilityHandler: mockHandler)

    // Test Denied
    mockHandler.cameraAuthorizationStatusResult = .denied
    let expectationDenied = expectation(description: "Denied error")
    plugin.callContext = ImagePickerMethodCallContext { _, error in
      XCTAssertEqual((error as? PigeonError)?.code, "camera_access_denied")
      expectationDenied.fulfill()
    }
    plugin.checkCameraAuthorization(with: UIImagePickerController(), camera: .rear)

    // Test Restricted
    mockHandler.cameraAuthorizationStatusResult = .restricted
    let expectationRestricted = expectation(description: "Restricted error")
    plugin.callContext = ImagePickerMethodCallContext { _, error in
      XCTAssertEqual((error as? PigeonError)?.code, "camera_access_restricted")
      expectationRestricted.fulfill()
    }
    plugin.checkCameraAuthorization(with: UIImagePickerController(), camera: .rear)

    waitForExpectations(timeout: 1)
  }

  func testCheckPhotoAuthorization_Denied_ReturnsError() {
    let mockHandler = MockDeviceCapabilityHandler()
    mockHandler.photoLibraryAuthorizationStatusResult = .denied
    let plugin = ImagePickerPlugin(
      viewProvider: StubViewProvider(), deviceCapabilityHandler: mockHandler)

    let expectation = self.expectation(description: "Denied error")
    plugin.callContext = ImagePickerMethodCallContext { _, error in
      XCTAssertEqual((error as? PigeonError)?.code, "photo_access_denied")
      expectation.fulfill()
    }
    plugin.checkPhotoAuthorization(with: UIViewController())

    waitForExpectations(timeout: 1)
  }

  func testCheckPhotoAuthorization_NotDetermined_Granted() {
    let mockHandler = MockDeviceCapabilityHandler()
    mockHandler.photoLibraryAuthorizationStatusResult = .notDetermined
    mockHandler.requestPhotoLibraryAuthorizationResult = .authorized
    let plugin = ImagePickerPlugin(
      viewProvider: StubViewProvider(viewController: UIViewController()),
      deviceCapabilityHandler: mockHandler)

    plugin.callContext = ImagePickerMethodCallContext { _, _ in }
    plugin.checkPhotoAuthorization(with: UIViewController())

    XCTAssertTrue(mockHandler.requestPhotoLibraryAuthorizationCalled)
  }

  func testErrorNoCameraAccess_Restricted_ReturnsCorrectCode() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "Restricted error")
    plugin.callContext = ImagePickerMethodCallContext { _, error in
      XCTAssertEqual((error as? PigeonError)?.code, "camera_access_restricted")
      expectation.fulfill()
    }
    plugin.errorNoCameraAccess(.restricted)
    waitForExpectations(timeout: 1)
  }

  func testErrorNoPhotoAccess_Denied_ReturnsCorrectCode() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "Denied error")
    plugin.callContext = ImagePickerMethodCallContext { _, error in
      XCTAssertEqual((error as? PigeonError)?.code, "photo_access_denied")
      expectation.fulfill()
    }
    plugin.errorNoPhotoAccess(.denied)
    waitForExpectations(timeout: 1)
  }

  func testPresentingViewController_WhenWindowExists_UsesBlocker() {
    let window = UIWindow()
    let viewController = UIViewController()
    window.rootViewController = viewController
    window.makeKeyAndVisible()

    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider(viewController: viewController))

    let result = plugin.presentingViewControllerForImagePickerInNewWindow()

    XCTAssertNotNil(plugin.interactionBlockerWindow)
    XCTAssertEqual(result, plugin.interactionBlockerWindow?.rootViewController)

    plugin.removeInteractionBlocker()
  }

  func testRemoveInteractionBlocker_ResetsKeyWindow() {
    let plugin = ImagePickerPlugin(
      viewProvider: StubViewProvider(viewController: UIViewController()))
    let window = UIWindow()
    plugin.interactionBlockerWindow = window
    plugin.previousKeyWindow = UIWindow()

    plugin.removeInteractionBlocker()

    XCTAssertNil(plugin.interactionBlockerWindow)
    XCTAssertNil(plugin.previousKeyWindow)
  }
}
