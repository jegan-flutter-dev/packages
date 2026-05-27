// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import Photos
import PhotosUI
import UIKit
import XCTest

@testable import image_picker_ios

@MainActor
class ImagePickerPluginDelegateTests: XCTestCase {

  func testImagePickerDelegate_DidFinishPickingImage_ReturnsResult() throws {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "Result returned")

    plugin.callContext = ImagePickerMethodCallContext { paths, _ in
      XCTAssertNotNil(paths)
      expectation.fulfill()
    }

    let image = try XCTUnwrap(UIImage(data: ImagePickerTestImages.jpgTestData))
    plugin.imagePickerController(
      UIImagePickerController(), didFinishPickingMediaWithInfo: [.originalImage: image])

    waitForExpectations(timeout: 1)
  }

  func testImagePickerDelegate_DidFinishPickingVideo_ReturnsResult() {
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
    let expectation = self.expectation(description: "Result returned")

    plugin.callContext = ImagePickerMethodCallContext { paths, error in
      XCTAssertNotNil(paths)
      XCTAssertNil(error)
      expectation.fulfill()
    }

    // Ensure the dummy video file exists so saveVideo doesn't fail.
    let videoURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.mp4")
    try? Data("test".utf8).write(to: videoURL)

    plugin.imagePickerController(
      UIImagePickerController(), didFinishPickingMediaWithInfo: [.mediaURL: videoURL])

    waitForExpectations(timeout: 1)
    try? FileManager.default.removeItem(at: videoURL)
  }

  func testPHPickerDelegate_DidFinishPicking_EmptyResults_SendsNil() {
    if #available(iOS 14, *) {
      let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())
      let expectation = self.expectation(description: "Nil returned")

      plugin.callContext = ImagePickerMethodCallContext { paths, _ in
        XCTAssertNil(paths)
        expectation.fulfill()
      }

      plugin.picker(PHPickerViewController(configuration: PHPickerConfiguration()), didFinishPicking: [])

      waitForExpectations(timeout: 1)
    }
  }

  func testPresentationControllerDidDismiss_SendsNil() {
    let expectation = self.expectation(description: "Returns nil on dismiss")
    let plugin = ImagePickerPlugin(viewProvider: StubViewProvider())

    plugin.callContext = ImagePickerMethodCallContext { paths, error in
      XCTAssertNil(paths)
      XCTAssertNil(error)
      expectation.fulfill()
    }

    plugin.presentationControllerDidDismiss(
      UIPresentationController(presentedViewController: UIViewController(), presenting: nil))

    waitForExpectations(timeout: 1)
  }
}
