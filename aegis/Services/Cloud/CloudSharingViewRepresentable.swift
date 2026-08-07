//
//  CloudSharingViewRepresentable.swift
//  aegis
//

import CloudKit
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Bridge to the system CKShare sharing UI.
struct CloudSharingViewRepresentable: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onError: ((Error) -> Void)?

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        context.coordinator.onError = onError
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onError: onError)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        var onError: ((Error) -> Void)?

        init(onError: ((Error) -> Void)?) {
            self.onError = onError
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            onError?(error)
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? { nil }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            String(localized: "settings.share.title")
        }
    }
}
#elseif canImport(AppKit)
import AppKit

struct CloudSharingViewRepresentable: NSViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onError: ((Error) -> Void)?

    func makeNSViewController(context: Context) -> NSViewController {
        // macOS sharing UI is presented from Settings as unavailable guidance.
        NSViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
