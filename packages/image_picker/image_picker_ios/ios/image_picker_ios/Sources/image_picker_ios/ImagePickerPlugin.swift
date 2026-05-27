// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

@objc(ImagePickerPlugin)
public class ImagePickerPlugin: NSObject, FlutterPlugin, ImagePickerApi,
    UINavigationControllerDelegate, UIImagePickerControllerDelegate,
    PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {

    var imagePickerControllerOverrides: [UIImagePickerController]?
    let viewProvider: ViewProvider
    let deviceCapabilityHandler: DeviceCapabilityHandler
    var interactionBlockerWindow: UIWindow?
    weak var previousKeyWindow: UIWindow?

    var callContext: ImagePickerMethodCallContext?

    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ImagePickerPlugin(
            viewProvider: DefaultViewProvider(registrar: registrar),
            deviceCapabilityHandler: DefaultDeviceCapabilityHandler()
        )
        ImagePickerApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.publish(instance)
    }

    init(
        viewProvider: ViewProvider,
        deviceCapabilityHandler: DeviceCapabilityHandler = DefaultDeviceCapabilityHandler()
    ) {
        self.viewProvider = viewProvider
        self.deviceCapabilityHandler = deviceCapabilityHandler
        super.init()
    }
}
