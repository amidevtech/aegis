//
//  CloudKitShareAcceptance.swift
//  aegis
//

import CloudKit
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Accepts CKShare invitations in the UIScene lifecycle (iOS 26+).
final class AegisAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role)
        configuration.delegateClass = AegisSceneDelegate.self
        return configuration
    }
}

final class AegisSceneDelegate: NSObject, UIWindowSceneDelegate {
    static var onAcceptShare: ((CKShare.Metadata) -> Void)?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            Self.onAcceptShare?(metadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        Self.onAcceptShare?(metadata)
    }
}
#elseif os(macOS)
import AppKit

final class AegisAppDelegate: NSObject, NSApplicationDelegate {
    static var onAcceptShare: ((CKShare.Metadata) -> Void)?

    func application(
        _ application: NSApplication,
        userDidAcceptCloudKitShareWith metadata: CKShare.Metadata
    ) {
        Self.onAcceptShare?(metadata)
    }
}
#endif
