//
//  SettingsView.swift
//  aegis
//

import CloudKit
import SwiftData
import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(MedicineRepository.self) private var repository
    @Environment(CloudSyncService.self) private var cloudSync
    @Environment(\.dismiss) private var dismiss

    @State private var activeShare: CKShare?
    @State private var isPresentingShare = false
    @State private var isPreparingShare = false
    @State private var shareErrorMessage: String?
    @State private var isPresentingPaywall = false
    @AppStorage("notifications.includeMedicineName") private var includeMedicineNameInNotifications = false

    private let cloudContainer = CKContainer(identifier: CloudSyncService.containerIdentifier)

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                notificationsSection
                if subscriptionStore.isPro {
                    syncSection
                    sharingSection
                }
                #if DEBUG
                debugSection
                #endif
            }
            .formStyle(.grouped)
            .navigationTitle(Text(L10n.Settings.title))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) { dismiss() }
                }
            }
            .task {
                await subscriptionStore.loadProducts()
                await repository.syncProState()
                await cloudSync.refreshAccountStatus()
            }
            .onChange(of: subscriptionStore.isPro) { _, _ in
                Task { await repository.syncProState() }
            }
            .sheet(isPresented: $isPresentingPaywall) {
                PaywallView()
            }
            #if canImport(UIKit) && !os(watchOS)
            .sheet(isPresented: $isPresentingShare) {
                if let activeShare {
                    CloudSharingViewRepresentable(
                        share: activeShare,
                        container: cloudContainer,
                        onError: { shareErrorMessage = $0.localizedDescription })
                }
            }
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 480)
        #endif
    }

    private var subscriptionSection: some View {
        Section(L10n.Settings.subscriptionSection) {
            LabeledContent(L10n.Settings.status) {
                Text(subscriptionStore.isPro ? L10n.Settings.statusPro : L10n.Settings.statusFree)
                    .foregroundStyle(
                        subscriptionStore.isPro ? Theme.Palette.opened : Theme.Palette.muted)
            }

            if subscriptionStore.isPro {
                Button(L10n.Settings.manageSubscription) {
                    openSubscriptionManagement()
                }
            } else {
                Button(L10n.Settings.upgrade) {
                    isPresentingPaywall = true
                }
            }

            Button(L10n.Paywall.restore) {
                Task { await subscriptionStore.restore() }
            }

            if let message = subscriptionStore.lastErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.danger)
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $includeMedicineNameInNotifications) {
                Text(L10n.Settings.notificationIncludeName)
            }
            .onChange(of: includeMedicineNameInNotifications) { _, _ in
                Task {
                    let medicines = (try? repository.fetchActiveMedicines()) ?? []
                    await NotificationService.shared.sync(medicines: medicines)
                }
            }
            Text(L10n.Settings.notificationIncludeNameFootnote)
                .font(.footnote)
                .foregroundStyle(Theme.Palette.muted)
        } header: {
            Text(L10n.Settings.notificationsSection)
        }
    }

    private var syncSection: some View {
        Section {
            LabeledContent(L10n.Settings.iCloudStatus) {
                Text(iCloudStatusText)
                    .foregroundStyle(Theme.Palette.muted)
            }

            if cloudSync.isRunning {
                Label(L10n.Settings.syncActive, systemImage: "checkmark.icloud.fill")
                    .foregroundStyle(Theme.Palette.opened)
            } else {
                Label(L10n.Settings.syncInactive, systemImage: "icloud.slash")
                    .foregroundStyle(Theme.Palette.warning)
            }

            Button(L10n.Settings.syncNow) {
                Task { await cloudSync.pullNow() }
            }
            .disabled(!cloudSync.isRunning)

            if let message = cloudSync.lastErrorMessage
                ?? repository.lastErrorMessage
                ?? shareErrorMessage
            {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.danger)
            }
        } header: {
            Text(L10n.Settings.syncSection)
        }
    }

    private var sharingSection: some View {
        Section {
            #if canImport(UIKit) && !os(watchOS)
            Button {
                Task { await presentShare() }
            } label: {
                if isPreparingShare {
                    ProgressView()
                } else {
                    Label(L10n.Settings.shareCabinet, systemImage: "person.3.fill")
                }
            }
            .disabled(isPreparingShare || !cloudSync.accountAvailable)

            Text(L10n.Settings.shareFootnote)
                .font(.footnote)
                .foregroundStyle(Theme.Palette.muted)
            #else
            Text(L10n.Settings.shareMacUnavailable)
                .font(.footnote)
                .foregroundStyle(Theme.Palette.muted)
            #endif
        } header: {
            Text(L10n.Settings.sharingSection)
        }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            Toggle(
                "Force Pro",
                isOn: Binding(
                    get: { subscriptionStore.debugProOverride == true },
                    set: { subscriptionStore.debugProOverride = $0 ? true : nil }))
        }
    }
    #endif

    private var iCloudStatusText: LocalizedStringResource {
        switch cloudSync.iCloudAccountStatus {
        case .available: L10n.Settings.iCloudAvailable
        case .noAccount: L10n.Settings.iCloudNoAccount
        case .restricted: L10n.Settings.iCloudRestricted
        case .couldNotDetermine: L10n.Settings.iCloudUnknown
        case .temporarilyUnavailable: L10n.Settings.iCloudUnavailable
        @unknown default: L10n.Settings.iCloudUnknown
        }
    }

    private func presentShare() async {
        isPreparingShare = true
        shareErrorMessage = nil
        defer { isPreparingShare = false }
        do {
            let share = try await cloudSync.prepareShare()
            activeShare = share
            #if canImport(UIKit) && !os(watchOS)
            isPresentingShare = true
            #endif
        } catch {
            shareErrorMessage = error.localizedDescription
        }
    }

    private func openSubscriptionManagement() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #elseif canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

#Preview {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return SettingsView()
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .environment(services.cloudSync)
        .modelContainer(container)
}
