//
//  RootView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Nawigacja główna. `sidebarAdaptable` daje pasek zakładek na iPhonie,
/// a boczny panel na iPadzie i Macu - najbliżej układu z szablonu webowego.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: MedicineQueries.active, sort: MedicineQueries.byExpiry)
    private var activeMedicines: [Medicine]

    /// Znacznik ostatniego pokazania arkusza, żeby nie wyskakiwał przy każdym powrocie do apki.
    @AppStorage("lastExpiredAlertTimestamp") private var lastAlertTimestamp: Double = 0

    @State private var isPresentingExpiredAlert = false
    @State private var hasEvaluatedOnLaunch = false

    private var expiredMedicines: [Medicine] {
        let now = Date.now
        return activeMedicines.filter { $0.status(now: now) == .expired }
    }

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            Tab(value: AppTab.overview) {
                DashboardView()
            } label: {
                Label(AppTab.overview.label, systemImage: AppTab.overview.symbolName)
            }

            Tab(value: AppTab.medicines) {
                MedicineListView()
            } label: {
                Label(AppTab.medicines.label, systemImage: AppTab.medicines.symbolName)
            }

            Tab(value: AppTab.archive) {
                ArchiveView()
            } label: {
                Label(AppTab.archive.label, systemImage: AppTab.archive.symbolName)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(Theme.Palette.brand)
        .sheet(isPresented: $appState.isPresentingNewMedicine) {
            MedicineFormView(mode: .create)
        }
        .sheet(isPresented: $isPresentingExpiredAlert) {
            ExpiredAlertSheet(medicines: expiredMedicines)
        }
        .task {
            guard !hasEvaluatedOnLaunch else { return }
            hasEvaluatedOnLaunch = true
            evaluateExpiredAlert(isColdLaunch: true)
            await NotificationService.shared.sync(medicines: activeMedicines)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                evaluateExpiredAlert(isColdLaunch: false)
            case .background:
                let medicines = activeMedicines
                Task { await NotificationService.shared.sync(medicines: medicines) }
            default:
                break
            }
        }
    }

    /// Arkusz pojawia się przy zimnym starcie oraz przy pierwszym otwarciu w danym dniu.
    private func evaluateExpiredAlert(isColdLaunch: Bool) {
        guard !isPresentingExpiredAlert, !expiredMedicines.isEmpty else { return }

        let lastShown = Date(timeIntervalSince1970: lastAlertTimestamp)
        let alreadyShownToday = lastAlertTimestamp > 0
            && Calendar.current.isDateInToday(lastShown)
        guard isColdLaunch || !alreadyShownToday else { return }

        lastAlertTimestamp = Date.now.timeIntervalSince1970
        isPresentingExpiredAlert = true
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .modelContainer(PreviewData.container)
}
