// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import Foundation

extension ImagePickerPlugin {
    func pickImage(
        source: SourceSpecification, maxSize: MaxSize, imageQuality: Int64?,
        requestFullMetadata: Bool,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        cancelInProgressCall()
        let context = ImagePickerMethodCallContext { paths, error in
            if let error = error {
                completion(.failure(error))
            } else if let paths = paths, paths.count > 1 {
                let pigeonError = PigeonError(
                    code: "invalid_result", message: "Incorrect number of return paths provided",
                    details: nil
                )
                completion(.failure(pigeonError))
            } else {
                completion(.success(paths?.first))
            }
        }
        context.includeImages = true
        context.maxSize = maxSize
        context.imageQuality = imageQuality != nil ? Double(imageQuality!) : nil
        context.maxItemCount = 1
        context.requestFullMetadata = requestFullMetadata

        if source.type == .gallery {
            if #available(iOS 14, *) {
                launchPHPicker(with: context)
            } else {
                launchUIImagePicker(with: source, context: context)
            }
        } else {
            launchUIImagePicker(with: source, context: context)
        }
    }

    func pickMultiImage(
        maxSize: MaxSize, imageQuality: Int64?, requestFullMetadata: Bool, limit: Int64?,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        cancelInProgressCall()
        let context = ImagePickerMethodCallContext { paths, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(paths ?? []))
            }
        }
        context.includeImages = true
        context.maxSize = maxSize
        context.imageQuality = imageQuality != nil ? Double(imageQuality!) : nil
        context.requestFullMetadata = requestFullMetadata
        context.maxItemCount = limit != nil ? Int(limit!) : 0

        if #available(iOS 14, *) {
            launchPHPicker(with: context)
        } else {
            launchUIImagePicker(
                with: SourceSpecification(type: .gallery, camera: .rear), context: context
            )
        }
    }

    func pickMedia(
        mediaSelectionOptions: MediaSelectionOptions,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        cancelInProgressCall()
        let context = ImagePickerMethodCallContext { paths, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(paths ?? []))
            }
        }
        context.maxSize = mediaSelectionOptions.maxSize
        context.imageQuality =
            mediaSelectionOptions.imageQuality != nil ? Double(mediaSelectionOptions.imageQuality!) : nil
        context.requestFullMetadata = mediaSelectionOptions.requestFullMetadata
        context.includeImages = true
        context.includeVideo = true
        if !mediaSelectionOptions.allowMultiple {
            context.maxItemCount = 1
        } else if let limit = mediaSelectionOptions.limit {
            context.maxItemCount = Int(limit)
        }

        if #available(iOS 14, *) {
            launchPHPicker(with: context)
        } else {
            launchUIImagePicker(
                with: SourceSpecification(type: .gallery, camera: .rear), context: context
            )
        }
    }

    func pickVideo(
        source: SourceSpecification, maxDurationSeconds: Int64?,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        cancelInProgressCall()
        let context = ImagePickerMethodCallContext { paths, error in
            if let error = error {
                completion(.failure(error))
            } else if let paths = paths, paths.count > 1 {
                let pigeonError = PigeonError(
                    code: "invalid_result", message: "Incorrect number of return paths provided",
                    details: nil
                )
                completion(.failure(pigeonError))
            } else {
                completion(.success(paths?.first))
            }
        }
        context.includeVideo = true
        context.maxItemCount = 1
        context.maxDuration = TimeInterval(maxDurationSeconds ?? 0)

        if source.type == .gallery {
            if #available(iOS 14, *) {
                launchPHPicker(with: context)
            } else {
                launchUIImagePicker(with: source, context: context)
            }
        } else {
            launchUIImagePicker(with: source, context: context)
        }
    }

    func pickMultiVideo(
        maxDurationSeconds: Int64?, limit: Int64?,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        cancelInProgressCall()
        let context = ImagePickerMethodCallContext { paths, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(paths ?? []))
            }
        }
        context.includeVideo = true
        context.maxItemCount = limit != nil ? Int(limit!) : 0
        context.maxDuration = TimeInterval(maxDurationSeconds ?? 0)

        if #available(iOS 14, *) {
            launchPHPicker(with: context)
        } else {
            launchUIImagePicker(
                with: SourceSpecification(type: .gallery, camera: .rear), context: context
            )
        }
    }
}
