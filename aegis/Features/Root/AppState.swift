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

/// Zawężenie listy leków wybierane kafelkami na ekranie przeglądu.
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

/// Stan nawigacji współdzielony przez zakładki, arkusze i menu na Macu.
@Observable
final class AppState {
    var selectedTab: AppTab = .overview
    var medicinesFilter: MedicineListFilter = .all
    var isPresentingNewMedicine = false
    var isPresentingPaywall = false
    var isPresentingSettings = false

    /// Prośba o przeniesienie kursora do pola wyszukiwania (skrót Command-F).
    /// Flaga, a nie zdarzenie, bo lista leków może dopiero powstawać po przełączeniu
    /// zakładki i przegapiłaby jednorazowy sygnał.
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
