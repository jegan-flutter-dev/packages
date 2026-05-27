// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import Flutter
import Photos
import UIKit

typealias FlutterResultAdapter = ([String]?, Error?) -> Void

/// Protocol for handling device capabilities and authorizations.
protocol DeviceCapabilityHandler {
    func isSourceTypeAvailable(_ sourceType: UIImagePickerController.SourceType) -> Bool
    func isCameraDeviceAvailable(_ cameraDevice: UIImagePickerController.CameraDevice) -> Bool
    func cameraAuthorizationStatus() -> AVAuthorizationStatus
    func requestCameraAccess(completionHandler: @escaping (Bool) -> Void)
    func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus
    func requestPhotoLibraryAuthorization(_ handler: @escaping (PHAuthorizationStatus) -> Void)
}

/// Default implementation of DeviceCapabilityHandler using system APIs.
final class DefaultDeviceCapabilityHandler: DeviceCapabilityHandler {
    func isSourceTypeAvailable(_ sourceType: UIImagePickerController.SourceType) -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(sourceType)
    }

    func isCameraDeviceAvailable(_ cameraDevice: UIImagePickerController.CameraDevice) -> Bool {
        return UIImagePickerController.isCameraDeviceAvailable(cameraDevice)
    }

    func cameraAuthorizationStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestCameraAccess(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completionHandler)
    }

    func photoLibraryAuthorizationStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }

    func requestPhotoLibraryAuthorization(_ handler: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(handler)
    }
}

class ImagePickerMethodCallContext {
    let result: FlutterResultAdapter
    var maxSize: MaxSize?
    var imageQuality: Double?
    var maxItemCount: Int = 0
    var requestFullMetadata: Bool = false
    var maxDuration: TimeInterval = 0
    var includeImages: Bool = false
    var includeVideo: Bool = false

    init(result: @escaping FlutterResultAdapter) {
        self.result = result
    }
}
