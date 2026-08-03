//
//  CloudSharingViewRepresentable.swift
//  aegis
//

import CloudKit
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Most do systemowego UI udostępniania CKShare.
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
            // Błąd jest też widoczny w systemowym UI.
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
        // macOS 12+: UICloudSharingController nie istnieje; używamy sheet z informacją
        // i linkiem — pełne NSSharingServicePicker wymaga dodatkowego mostu.
        // Prezentujemy pusty host; SettingsView pokazuje instrukcję gdy share już istnieje.
        NSViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
