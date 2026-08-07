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
    @State private var dismissedErrorMessage: String?

    private var expiredMedicines: [Medicine] {
        let now = Date.now
        return activeMedicines.filter { $0.status(now: now) == .expired }
    }

    private var activeErrorMessage: String? {
        if let message = repository.lastErrorMessage, !message.isEmpty {
            return message
        }
        if let message = cloudSync.lastErrorMessage, !message.isEmpty {
            return message
        }
        return nil
    }

    private var visibleErrorMessage: String? {
        guard let message = activeErrorMessage, message != dismissedErrorMessage else { return nil }
        return message
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
        .safeAreaInset(edge: .bottom) {
            if let message = visibleErrorMessage {
                errorBanner(message)
            }
        }
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
            _ = await NotificationService.shared.requestAuthorizationIfNeeded()
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
        .onChange(of: activeErrorMessage) { _, newValue in
            if newValue == nil {
                dismissedErrorMessage = nil
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.Palette.danger)
                .accessibilityHidden(true)

            Text(message)
                .font(.footnote)
                .foregroundStyle(Theme.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismissedErrorMessage = message
                repository.clearError()
                cloudSync.clearError()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.Palette.muted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.Common.done))
        }
        .padding(12)
        .background(Theme.softBackground(Theme.Palette.danger), in: .rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
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
