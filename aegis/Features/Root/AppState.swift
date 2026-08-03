//
//  AppState.swift
//  aegis
//

import Foundation
import SwiftUI

enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case overview
    case medicines
    case archive

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .overview: L10n.Tab.overview
        case .medicines: L10n.Tab.medicines
        case .archive: L10n.Tab.archive
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "house.fill"
        case .medicines: "cross.case.fill"
        case .archive: "archivebox.fill"
        }
    }
}

/// Medicine list filter chosen via overview tiles.
enum MedicineListFilter: String, Hashable, CaseIterable, Identifiable {
    case all
    case opened
    case expiringSoon

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .all: L10n.Dashboard.statActiveTitle
        case .opened: L10n.Dashboard.statOpenedTitle
        case .expiringSoon: L10n.Dashboard.statExpiringTitle
        }
    }

    func matches(_ medicine: Medicine, now: Date) -> Bool {
        switch self {
        case .all: true
        case .opened: medicine.isOpened
        case .expiringSoon: medicine.status(now: now) != .valid
        }
    }
}

/// Navigation state shared across tabs, sheets, and the Mac menu.
@Observable
final class AppState {
    var selectedTab: AppTab = .overview
    var medicinesFilter: MedicineListFilter = .all
    var isPresentingNewMedicine = false
    var isPresentingPaywall = false
    var isPresentingSettings = false

    /// Request to move focus to the search field (Command-F shortcut).
    /// Stored as a flag rather than an event, because the medicines list may still
    /// be appearing after a tab switch and would miss a one-shot signal.
    var isSearchFocusRequested = false

    func showMedicines(filter: MedicineListFilter) {
        medicinesFilter = filter
        selectedTab = .medicines
    }

    func focusSearch() {
        selectedTab = .medicines
        isSearchFocusRequested = true
    }

    func presentPaywall() {
        isPresentingPaywall = true
    }
}
