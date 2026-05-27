// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import Photos
import PhotosUI
import UIKit

extension ImagePickerPlugin {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_: UIPresentationController) {
        sendCallResult(pathList: nil)
    }

    // MARK: - PHPickerViewControllerDelegate

    @available(iOS 14, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        if results.isEmpty {
            sendCallResult(pathList: nil)
            return
        }

        handlePickerResults(results)
    }

    @available(iOS 14, *)
    func handlePickerResults(_ results: [PHPickerResult]) {
        let saveQueue = OperationQueue()
        saveQueue.name = "Flutter Save Image Queue"
        saveQueue.qualityOfService = .userInitiated

        guard let currentCallContext = callContext else { return }
        let maxWidth = currentCallContext.maxSize?.width
        let maxHeight = currentCallContext.maxSize?.height
        let imageQuality = currentCallContext.imageQuality
        let desiredImageQuality = getDesiredImageQuality(imageQuality)
        let requestFullMetadata = currentCallContext.requestFullMetadata

        var pathList = [String?](repeating: nil, count: results.count)
        var saveError: Error?

        let sendListOperation = BlockOperation {
            DispatchQueue.main.async {
                if let error = saveError {
                    self.sendCallResult(error: error)
                } else {
                    self.sendCallResult(pathList: pathList.compactMap { $0 })
                }
            }
        }

        for (index, result) in results.enumerated() {
            let saveOperation = PHPickerSaveImageToPathOperation(
                itemProvider: result.itemProvider,
                maxHeight: maxHeight,
                maxWidth: maxWidth,
                desiredImageQuality: desiredImageQuality,
                fullMetadata: requestFullMetadata
            ) { savedPath, error in
                if let savedPath = savedPath {
                    pathList[index] = savedPath
                } else {
                    saveError = error
                }
            }
            sendListOperation.addDependency(saveOperation)
            saveQueue.addOperation(saveOperation)
        }

        OperationQueue.main.addOperation(sendListOperation)
    }

    // MARK: - UIImagePickerControllerDelegate

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let videoURL = info[.mediaURL] as? URL
        picker.dismiss(animated: true) { [weak self] in
            self?.removeInteractionBlocker()
        }

        if callContext == nil {
            return
        }

        if let videoURL = videoURL {
            handleVideoSelected(videoURL)
        } else {
            handleImageSelected(info)
        }
    }

    private func handleVideoSelected(_ videoURL: URL) {
        if #available(iOS 13.0, *) {
            guard let destination = ImagePickerPhotoAssetUtil.saveVideo(from: videoURL) else {
                let pigeonError = PigeonError(
                    code: "flutter_image_picker_copy_video_error", message: "Could not cache the video file.",
                    details: nil
                )
                sendCallResult(error: pigeonError)
                return
            }
            sendCallResult(pathList: [destination.path])
        } else {
            sendCallResult(pathList: [videoURL.path])
        }
    }

    private func handleImageSelected(_ info: [UIImagePickerController.InfoKey: Any]) {
        var image = info[.editedImage] as? UIImage
        if image == nil {
            image = info[.originalImage] as? UIImage
        }

        guard let image = image else {
            let pigeonError = PigeonError(
                code: "invalid_image", message: "Could not get image from picker", details: nil
            )
            sendCallResult(error: pigeonError)
            return
        }

        let maxWidth = callContext?.maxSize?.width
        let maxHeight = callContext?.maxSize?.height
        let imageQuality = callContext?.imageQuality
        let desiredImageQuality = getDesiredImageQuality(imageQuality)

        var originalAsset: PHAsset?
        if callContext?.requestFullMetadata == true {
            originalAsset = ImagePickerPhotoAssetUtil.getAsset(from: info)
        }

        var processedImage = image
        if maxWidth != nil || maxHeight != nil {
            processedImage = ImagePickerImageUtil.scaledImage(
                image,
                maxWidth: maxWidth,
                maxHeight: maxHeight,
                isMetadataAvailable: true
            )
        }

        if originalAsset == nil {
            saveImage(withPickerInfo: info, image: processedImage, imageQuality: desiredImageQuality)
        } else {
            fetchOriginalImageData(for: originalAsset!) { [weak self] imageData in
                self?.saveImage(
                    withOriginalImageData: imageData,
                    image: processedImage,
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                    imageQuality: desiredImageQuality
                )
            }
        }
    }

    private func fetchOriginalImageData(for asset: PHAsset, completion: @escaping (Data?) -> Void) {
        if #available(iOS 13.0, *) {
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset, options: nil
            ) { data, _, _, _ in
                completion(data)
            }
        } else {
            PHImageManager.default().requestImageData(for: asset, options: nil) { data, _, _, _ in
                completion(data)
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.removeInteractionBlocker()
        }
        sendCallResult(pathList: nil)
    }
}
