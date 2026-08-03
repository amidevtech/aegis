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

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            // The error is also visible in the system UI.
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

    func makeNSViewController(context: Context) -> NSViewController {
        // macOS 12+: UICloudSharingController does not exist; we use an info sheet
        // with a link — full NSSharingServicePicker needs an extra bridge.
        // Present an empty host; SettingsView shows instructions when a share already exists.
        NSViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
