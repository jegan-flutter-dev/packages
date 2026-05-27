// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import Flutter
import Photos
import UIKit

@testable import image_picker_ios

class MockUIImagePickerController: UIImagePickerController {
  var mockIsBeingPresented = false
  override var isBeingPresented: Bool {
    return mockIsBeingPresented
  }

  private var _sourceType: UIImagePickerController.SourceType = .photoLibrary
  override var sourceType: UIImagePickerController.SourceType {
    get { return _sourceType }
    set { _sourceType = newValue }
  }

  override var cameraDevice: UIImagePickerController.CameraDevice {
    get { return .rear }
    set {}
  }
}

class StubViewProvider: ViewProvider {
  var viewController: UIViewController?
  init(viewController: UIViewController? = nil) {
    self.viewController = viewController
  }
}

class MockDeviceCapabilityHandler: DeviceCapabilityHandler {
  var isSourceTypeAvailableResult = true
  var isSourceTypeAvailableCalled = false
  var isCameraDeviceAvailableResult = true
  var cameraAuthorizationStatusResult: AVAuthorizationStatus = .authorized
  var photoLibraryAuthorizationStatusResult: PHAuthorizationStatus = .authorized
  var photoLibraryAuthorizationStatusCalled = false
  var requestCameraAccessResult = true
  var requestCameraAccessCalled = false
  var requestPhotoLibraryAuthorizationResult: PHAuthorizationStatus = .authorized
  var requestPhotoLibraryAuthorizationCalled = false

  func isSourceTypeAvailable(_: UIImagePickerController.SourceType) -> Bool {
    isSourceTypeAvailableCalled = true
    return isSourceTypeAvailableResult
  }

  func isCameraDeviceAvailable(_: UIImagePickerController.CameraDevice) -> Bool {
    return isCameraDeviceAvailableResult
  }

  func cameraAuthorizationStatus() -> AVAuthorizationStatus {
    return cameraAuthorizationStatusResult
  }

  func requestCameraAccess(completionHandler: @escaping (Bool) -> Void) {
    requestCameraAccessCalled = true
    completionHandler(requestCameraAccessResult)
  }

  func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
    photoLibraryAuthorizationStatusCalled = true
    return photoLibraryAuthorizationStatusResult
  }

  func requestPhotoLibraryAuthorization(_ handler: @escaping (PHAuthorizationStatus) -> Void) {
    requestPhotoLibraryAuthorizationCalled = true
    handler(requestPhotoLibraryAuthorizationResult)
  }
}

class TestPluginRegistrar: NSObject, FlutterPluginRegistrar, @unchecked Sendable {
  var publishedInstance: Any?
  func messenger() -> FlutterBinaryMessenger {
    return TestBinaryMessenger()
  }

  func textures() -> FlutterTextureRegistry {
    fatalError()
  }

  func register(_: FlutterPlatformViewFactory, withId _: String) {}
  func register(
    _: FlutterPlatformViewFactory, withId _: String,
    gestureRecognizersBlockingPolicy _: FlutterPlatformViewGestureRecognizersBlockingPolicy
  ) {}
  func publish(_ value: NSObject) {
    publishedInstance = value
  }

  func addMethodCallDelegate(_: FlutterPlugin, channel _: FlutterMethodChannel) {}
  func addApplicationDelegate(_: FlutterPlugin) {}
  var viewController: UIViewController? {
    return nil
  }

  func lookupKey(forAsset _: String) -> String {
    return ""
  }

  func lookupKey(forAsset _: String, fromPackage _: String) -> String {
    return ""
  }

  func addSceneDelegate(_: FlutterSceneLifeCycleDelegate) {}
}

class TestBinaryMessenger: NSObject, FlutterBinaryMessenger, @unchecked Sendable {
  var handlers: [String: FlutterBinaryMessageHandler] = [:]
  func send(onChannel _: String, message _: Data?) {}
  func send(onChannel _: String, message _: Data?, binaryReply _: FlutterBinaryReply? = nil) {}
  func setMessageHandlerOnChannel(
    _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil
  ) -> FlutterBinaryMessengerConnection {
    if let handler = handler {
      handlers[channel] = handler
    } else {
      handlers.removeValue(forKey: channel)
    }
    return 0
  }

  func cleanUpConnection(_: FlutterBinaryMessengerConnection) {}
}
