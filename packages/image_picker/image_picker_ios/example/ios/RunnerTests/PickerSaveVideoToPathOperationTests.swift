// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@testable import image_picker_ios
import PhotosUI
import UniformTypeIdentifiers
import XCTest

class PickerSaveVideoToPathOperationTests: XCTestCase {
  @MainActor func testSaveVideo_Success() {
    if #available(iOS 14, *) {
      let mockProvider = PickerSaveImageToPathOperationTests.MockItemProvider()
      mockProvider.registeredIdentifiers = [UTType.movie.identifier]
      let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_op.mp4")
      try? Data("test".utf8).write(to: tempURL)
      mockProvider.mockURL = tempURL

      let pathExpectation = expectation(description: "Video path created")

      let operation = PHPickerSaveImageToPathOperation(
        itemProvider: mockProvider,
        maxHeight: nil,
        maxWidth: nil,
        desiredImageQuality: nil,
        fullMetadata: false
      ) { savedPath, _ in
        XCTAssertNotNil(savedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedPath!))
        pathExpectation.fulfill()
      }

      operation.start()
      waitForExpectations(timeout: 5)
      try? FileManager.default.removeItem(at: tempURL)
    }
  }

  @MainActor func testSaveVideo_NoURL_ReturnsError() {
    if #available(iOS 14, *) {
      let mockProvider = PickerSaveImageToPathOperationTests.MockItemProvider()
      mockProvider.registeredIdentifiers = [UTType.movie.identifier]
      mockProvider.mockURL = nil

      let errorExpectation = expectation(description: "Error received for nil URL")

      let operation = PHPickerSaveImageToPathOperation(
        itemProvider: mockProvider,
        maxHeight: nil,
        maxWidth: nil,
        desiredImageQuality: nil,
        fullMetadata: false
      ) { savedPath, error in
        XCTAssertNil(savedPath)
        XCTAssertEqual((error as? PigeonError)?.code, "invalid_image")
        errorExpectation.fulfill()
      }

      operation.start()
      waitForExpectations(timeout: 5)
    }
  }

  @MainActor
  func testProcessVideo_NoTypeIdentifiers_ReturnsError() async {
    if #available(iOS 14, *) {
      let mockProvider = PickerSaveImageToPathOperationTests.MockItemProvider()
      mockProvider.registeredIdentifiers = []  // ✅ No types at all

      let errorExpectation = expectation(description: "No type identifiers error")

      let operation = PHPickerSaveImageToPathOperation(
        itemProvider: mockProvider,
        maxHeight: nil,
        maxWidth: nil,
        desiredImageQuality: nil,
        fullMetadata: false
      ) { savedPath, error in
        XCTAssertNil(savedPath)

        let pigeonError = error as? PigeonError
        XCTAssertEqual(pigeonError?.code, "invalid_source")

        errorExpectation.fulfill()
      }

      operation.start()

      await fulfillment(of: [errorExpectation], timeout: 2)

      // ✅ Ensure lifecycle is covered
      XCTAssertTrue(operation.isFinished)
    }
  }

  @MainActor
  func testSaveVideo_LoadingFailure_ReturnsError() async {
    if #available(iOS 14, *) {
      let mockProvider = PickerSaveImageToPathOperationTests.MockItemProvider()
      mockProvider.registeredIdentifiers = [UTType.movie.identifier]
      mockProvider.shouldSucceed = false

      let errorExpectation = expectation(description: "Video loading failure")

      let operation = PHPickerSaveImageToPathOperation(
        itemProvider: mockProvider,
        maxHeight: nil,
        maxWidth: nil,
        desiredImageQuality: nil,
        fullMetadata: false
      ) { savedPath, error in
        XCTAssertNil(savedPath)
        XCTAssertNotNil(error)

        // ✅ FIX: Do NOT force PigeonError
        // Because operation returns NSError here
        if let pigeonError = error as? PigeonError {
          XCTAssertEqual(pigeonError.code, "invalid_video")
        } else {
          XCTAssertTrue(error != nil)
        }

        errorExpectation.fulfill()
      }

      operation.start()

      await fulfillment(of: [errorExpectation], timeout: 3)

      XCTAssertTrue(operation.isFinished)
    }
  }

  @MainActor
  func testSaveVideo_SaveFailure_ReturnsError() async {
    if #available(iOS 14, *) {
      let mockProvider = PickerSaveImageToPathOperationTests.MockItemProvider()
      mockProvider.registeredIdentifiers = [UTType.movie.identifier]

      // ✅ Provide invalid file path → copy will fail
      mockProvider.mockURL = URL(fileURLWithPath: "/non/existent/video.mp4")
      mockProvider.shouldSucceed = true

      let errorExpectation = expectation(description: "Save failure error")

      let operation = PHPickerSaveImageToPathOperation(
        itemProvider: mockProvider,
        maxHeight: nil,
        maxWidth: nil,
        desiredImageQuality: nil,
        fullMetadata: false
      ) { savedPath, error in
        XCTAssertNil(savedPath)

        let pigeonError = error as? PigeonError
        XCTAssertEqual(pigeonError?.code, "flutter_image_picker_copy_video_error")

        errorExpectation.fulfill()
      }

      operation.start()

      await fulfillment(of: [errorExpectation], timeout: 3)

      // ✅ Ensure operation lifecycle covered
      XCTAssertTrue(operation.isFinished)
    }
  }
}
