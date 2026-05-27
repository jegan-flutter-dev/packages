// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import Flutter
import MobileCoreServices
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

extension ImagePickerPlugin {
    func createImagePickerController() -> UIImagePickerController {
        if let overrides = imagePickerControllerOverrides, !overrides.isEmpty {
            return imagePickerControllerOverrides!.removeFirst()
        }
        return UIImagePickerController()
    }

    func setImagePickerControllerOverrides(_ overrides: [UIImagePickerController]) {
        imagePickerControllerOverrides = overrides
    }

    func cameraDevice(for source: SourceSpecification) -> UIImagePickerController.CameraDevice {
        switch source.camera {
        case .front:
            return .front
        case .rear:
            return .rear
        }
    }

    @available(iOS 14, *)
    func launchPHPicker(with context: ImagePickerMethodCallContext) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = max(0, context.maxItemCount)
        config.preferredAssetRepresentationMode = .current

        var filters: [PHPickerFilter] = []
        if context.includeImages {
            filters.append(.images)
        }
        if context.includeVideo {
            filters.append(.videos)
        }
        if !filters.isEmpty {
            config.filter = .any(of: filters)
        }

        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        pickerViewController.presentationController?.delegate = self
        callContext = context

        if context.requestFullMetadata {
            checkPhotoAuthorization(with: pickerViewController)
        } else {
            showPhotoLibrary(with: pickerViewController)
        }
    }

    func launchUIImagePicker(
        with source: SourceSpecification, context: ImagePickerMethodCallContext
    ) {
        let imagePickerController = createImagePickerController()
        imagePickerController.modalPresentationStyle = .currentContext
        imagePickerController.delegate = self

        var mediaTypes: [String] = []
        if context.includeImages {
            if #available(iOS 14.0, *) {
                mediaTypes.append(UTType.image.identifier)
            } else {
                mediaTypes.append(kUTTypeImage as String)
            }
        }
        if context.includeVideo {
            if #available(iOS 14.0, *) {
                mediaTypes.append(UTType.movie.identifier)
            } else {
                mediaTypes.append(kUTTypeMovie as String)
            }
            imagePickerController.videoQuality = .typeHigh
        }
        imagePickerController.mediaTypes = mediaTypes
        if context.maxDuration != 0.0 {
            imagePickerController.videoMaximumDuration = context.maxDuration
        }

        callContext = context

        switch source.type {
        case .camera:
            checkCameraAuthorization(
                with: imagePickerController, camera: cameraDevice(for: source)
            )
        case .gallery:
            if context.requestFullMetadata {
                checkPhotoAuthorization(with: imagePickerController)
            } else {
                showPhotoLibrary(with: imagePickerController)
            }
        }
    }

    func cancelInProgressCall() {
        if callContext != nil {
            let pigeonError = PigeonError(
                code: "multiple_request", message: "Cancelled by a second request", details: nil
            )
            sendCallResult(error: pigeonError)
            callContext = nil
        }
    }

    func showCamera(
        _ device: UIImagePickerController.CameraDevice,
        with imagePickerController: UIImagePickerController
    ) {
        if imagePickerController.isBeingPresented {
            return
        }

        if deviceCapabilityHandler.isSourceTypeAvailable(.camera),
           deviceCapabilityHandler.isCameraDeviceAvailable(device) {
            imagePickerController.sourceType = .camera
            imagePickerController.cameraDevice = device
            let presentingController = presentingViewControllerForImagePickerInNewWindow()
            presentingController.present(imagePickerController, animated: true)
        } else {
            let cameraErrorAlert = UIAlertController(
                title: NSLocalizedString("Error", comment: "Alert title when camera unavailable"),
                message: NSLocalizedString("Camera not available.", comment: "Alert message when camera unavailable"),
                preferredStyle: .alert
            )
            cameraErrorAlert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("OK", comment: "Alert button when camera unavailable"),
                    style: .default
                )
            )
            viewProvider.viewController?.present(cameraErrorAlert, animated: true)
            sendCallResult(pathList: nil)
        }
    }

    func checkCameraAuthorization(
        with imagePickerController: UIImagePickerController,
        camera device: UIImagePickerController.CameraDevice
    ) {
        let status = deviceCapabilityHandler.cameraAuthorizationStatus()

        switch status {
        case .authorized:
            showCamera(device, with: imagePickerController)
        case .notDetermined:
            deviceCapabilityHandler.requestCameraAccess { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.showCamera(device, with: imagePickerController)
                    } else {
                        self?.errorNoCameraAccess(.denied)
                    }
                }
            }
        case .denied, .restricted:
            errorNoCameraAccess(status)
        @unknown default:
            errorNoCameraAccess(status)
        }
    }

    func checkPhotoAuthorization(with pickerViewController: UIViewController) {
        let status = deviceCapabilityHandler.photoLibraryAuthorizationStatus()
        switch status {
        case .notDetermined:
            deviceCapabilityHandler.requestPhotoLibraryAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if #available(iOS 14, *) {
                        if status == .authorized || status == .limited {
                            self?.showPhotoLibrary(with: pickerViewController)
                        } else {
                            self?.errorNoPhotoAccess(status)
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        case .authorized, .limited:
            showPhotoLibrary(with: pickerViewController)
        case .denied, .restricted:
            errorNoPhotoAccess(status)
        @unknown default:
            errorNoPhotoAccess(status)
        }
    }

    func errorNoCameraAccess(_ status: AVAuthorizationStatus) {
        let code = status == .restricted ? "camera_access_restricted" : "camera_access_denied"
        let message =
            status == .restricted
                ? "The user is not allowed to use the camera." : "The user did not allow camera access."
        let pigeonError = PigeonError(code: code, message: message, details: nil)
        sendCallResult(error: pigeonError)
    }

    func errorNoPhotoAccess(_ status: PHAuthorizationStatus) {
        let code = status == .restricted ? "photo_access_restricted" : "photo_access_denied"
        let message =
            status == .restricted
                ? "The user is not allowed to use the photo library." : "The user did not allow photo library access."
        let pigeonError = PigeonError(code: code, message: message, details: nil)
        sendCallResult(error: pigeonError)
    }

    func showPhotoLibrary(with pickerViewController: UIViewController) {
        if let imagePicker = pickerViewController as? UIImagePickerController {
            imagePicker.sourceType = .photoLibrary
        }
        viewProvider.viewController?.present(pickerViewController, animated: true)
    }

    func getDesiredImageQuality(_ imageQuality: Double?) -> Double {
        guard let quality = imageQuality else { return 1.0 }
        if quality < 0 || quality > 100 {
            return 1.0
        }
        return quality / 100.0
    }

    func saveImage(
        withOriginalImageData originalImageData: Data?,
        image: UIImage,
        maxWidth: Double?,
        maxHeight: Double?,
        imageQuality: Double?
    ) {
        let savedPath = ImagePickerPhotoAssetUtil.saveImage(
            with: originalImageData,
            image: image,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            imageQuality: imageQuality
        )
        sendCallResult(pathList: savedPath != nil ? [savedPath!] : [])
    }

    func saveImage(
        withPickerInfo info: [UIImagePickerController.InfoKey: Any],
        image: UIImage,
        imageQuality: Double?
    ) {
        let savedPath = ImagePickerPhotoAssetUtil.saveImage(
            with: info,
            image: image,
            imageQuality: imageQuality
        )
        sendCallResult(pathList: savedPath != nil ? [savedPath!] : [])
    }

    func sendCallResult(pathList: [String]? = nil, error: Error? = nil) {
        guard let context = callContext else { return }
        context.result(pathList, error)
        callContext = nil
    }

    func presentingViewControllerForImagePickerInNewWindow() -> UIViewController {
        if let blocker = interactionBlockerWindow {
            return blocker.rootViewController!
        }

        guard let topController = viewProvider.viewController,
              let presentingWindow = topController.view.window
        else {
            return viewProvider.viewController!
        }

        previousKeyWindow = presentingWindow
        let blockerWindow: UIWindow
        if #available(iOS 13.0, *) {
            if let windowScene = presentingWindow.windowScene {
                blockerWindow = UIWindow(windowScene: windowScene)
            } else {
                blockerWindow = UIWindow(frame: presentingWindow.bounds)
            }
        } else {
            blockerWindow = UIWindow(frame: presentingWindow.bounds)
        }

        blockerWindow.frame = presentingWindow.bounds
        blockerWindow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blockerWindow.windowLevel = presentingWindow.windowLevel + 1

        let blockerViewController = UIViewController()
        blockerViewController.view.backgroundColor = .clear
        blockerViewController.view.isUserInteractionEnabled = true
        blockerWindow.rootViewController = blockerViewController
        blockerWindow.makeKeyAndVisible()
        interactionBlockerWindow = blockerWindow
        return blockerViewController
    }

    func removeInteractionBlocker() {
        guard let blocker = interactionBlockerWindow else { return }
        blocker.isHidden = true
        previousKeyWindow?.makeKey()
        interactionBlockerWindow = nil
        previousKeyWindow = nil
    }
}
