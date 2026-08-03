//
//  RootView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Root navigation. `sidebarAdaptable` gives a tab bar on iPhone
/// and a sidebar on iPad and Mac — closest to the web template layout.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(MedicineRepository.self) private var repository
    @Environment(CloudSyncService.self) private var cloudSync
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: MedicineQueries.active, sort: MedicineQueries.byExpiry)
    private var activeMedicines: [Medicine]

    /// Timestamp of the last sheet presentation, so it does not pop up on every return to the app.
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

            if subscriptionStore.isPro {
                Tab(value: AppTab.archive) {
                    ArchiveView()
                } label: {
                    Label(AppTab.archive.label, systemImage: AppTab.archive.symbolName)
                }
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
        .sheet(isPresented: $appState.isPresentingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $appState.isPresentingSettings) {
            SettingsView()
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
                if subscriptionStore.isPro {
                    Task { await cloudSync.pullNow() }
                }
            case .background:
                let medicines = activeMedicines
                Task { await NotificationService.shared.sync(medicines: medicines) }
            default:
                break
            }
        }
        .onChange(of: subscriptionStore.isPro) { _, isPro in
            if !isPro, appState.selectedTab == .archive {
                appState.selectedTab = .overview
            }
        }
    }

    /// The sheet appears on cold launch and on the first open of the day.
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
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return RootView()
        .environment(AppState())
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .environment(services.cloudSync)
        .modelContainer(container)
}
