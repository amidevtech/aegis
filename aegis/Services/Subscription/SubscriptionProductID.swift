//
//  SubscriptionProductID.swift
//  aegis
//

import Foundation

/// Identyfikatory produktów subskrypcji w App Store Connect / Configuration.storekit.
enum SubscriptionProductID: String, CaseIterable, Identifiable, Sendable {
    case monthly = "com.amidev.aegis.pro.monthly"
    case yearly = "com.amidev.aegis.pro.yearly"

    var id: String { rawValue }

    static var allIDs: [String] { allCases.map(\.rawValue) }
}
