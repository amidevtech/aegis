//
//  DashboardView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Overview screen: subtitle, three summary tiles, medicine list, and a panel
/// for expired medicines — layout carried over from the web template.
struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(MedicineRepository.self) private var repository
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: MedicineQueries.active, sort: MedicineQueries.byExpiry)
    private var medicines: [Medicine]

    @State private var medicinesPendingDeletion: [Medicine] = []
    @State private var now = Date.now

    private static let previewRowLimit = 5

    private var openedCount: Int {
        medicines.count { $0.isOpened }
    }

    private var expiringSoonCount: Int {
        medicines.count { $0.status(now: now) == .expiringSoon }
    }

    private var expiredMedicines: [Medicine] {
        medicines.filter { $0.status(now: now) == .expired }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
                    heading
                    statsGrid
                    panels
                }
                .padding(20)
                .frame(maxWidth: 1100, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.canvas)
            .navigationTitle(Text(L10n.App.title))
            .toolbar {
                ToolbarItem {
                    Button {
                        appState.isPresentingSettings = true
                    } label: {
                        Label(L10n.Settings.title, systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.isPresentingNewMedicine = true
                    } label: {
                        Label(L10n.Medicines.add, systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Medicine.self) { medicine in
                MedicineDetailView(medicine: medicine)
            }
            .confirmationDialog(
                Text(L10n.Medicines.deleteConfirmTitle),
                isPresented: bulkDeleteDialogBinding,
                titleVisibility: .visible
            ) {
                Button(L10n.Common.delete, role: .destructive) {
                    for medicine in medicinesPendingDeletion {
                        MedicineActions.delete(medicine, in: repository)
                    }
                    medicinesPendingDeletion = []
                }
                Button(L10n.Common.cancel, role: .cancel) {
                    medicinesPendingDeletion = []
                }
            } message: {
                Text(L10n.Medicines.deleteConfirmMessage)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { now = .now }
            }
        }
    }

    private var bulkDeleteDialogBinding: Binding<Bool> {
        Binding(
            get: { !medicinesPendingDeletion.isEmpty },
            set: { if !$0 { medicinesPendingDeletion = [] } })
    }

    // MARK: - Header

    private var heading: some View {
        Text(L10n.Dashboard.subtitle)
            .font(.title3)
            .foregroundStyle(Theme.Palette.muted)
    }

    // MARK: - Tiles

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 260), spacing: 12)],
            spacing: 12
        ) {
            StatCard(
                title: L10n.Dashboard.statActiveTitle,
                caption: L10n.Dashboard.statActiveCaption,
                value: medicines.count,
                systemImage: "cross.case.fill",
                tint: Theme.Palette.brandDeep) {
                    appState.showMedicines(filter: .all)
                }

            StatCard(
                title: L10n.Dashboard.statOpenedTitle,
                caption: L10n.Dashboard.statOpenedCaption,
                value: openedCount,
                systemImage: "checkmark.seal.fill",
                tint: Theme.Palette.opened) {
                    appState.showMedicines(filter: .opened)
                }

            StatCard(
                title: L10n.Dashboard.statExpiringTitle,
                caption: L10n.Dashboard.statExpiringCaption,
                value: expiringSoonCount,
                systemImage: "clock.badge.exclamationmark.fill",
                tint: Theme.Palette.warning) {
                    appState.showMedicines(filter: .expiringSoon)
                }
        }
    }

    // MARK: - Panels

    private var panels: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Theme.Metrics.sectionSpacing) {
                medicinePanel.frame(minWidth: 420)
                attentionPanel.frame(minWidth: 320)
            }
            VStack(spacing: Theme.Metrics.sectionSpacing) {
                medicinePanel
                attentionPanel
            }
        }
    }

    private var medicinePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.Dashboard.medicinesTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                if !medicines.isEmpty {
                    Button(L10n.Dashboard.seeAll) {
                        appState.showMedicines(filter: .all)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
                }
            }

            if medicines.isEmpty {
                EmptyStateView(
                    systemImage: "cross.case",
                    title: L10n.Dashboard.emptyTitle,
                    message: L10n.Dashboard.emptyMessage,
                    actionTitle: L10n.Medicines.add) {
                        appState.isPresentingNewMedicine = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(medicines.prefix(Self.previewRowLimit).enumerated()),
                            id: \.element.uuid) { index, medicine in
                        if index > 0 {
                            Divider().overlay(Theme.Palette.outline)
                        }
                        NavigationLink(value: medicine) {
                            MedicineRow(medicine: medicine, now: now)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var attentionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SymbolTile(
                    systemName: "exclamationmark.triangle.fill",
                    tint: Theme.Palette.danger,
                    size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Dashboard.attentionTitle)
                        .font(.title3.bold())
                        .foregroundStyle(Theme.Palette.danger)
                    Text(L10n.Dashboard.attentionCount(expiredMedicines.count))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }

            if expiredMedicines.isEmpty {
                Label {
                    Text(L10n.Dashboard.attentionAllGood)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.opened)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(expiredMedicines, id: \.uuid) { medicine in
                        expiredRow(medicine)
                    }
                }

                Button(role: .destructive) {
                    removeExpired(expiredMedicines)
                } label: {
                    Text(subscriptionStore.isPro ? L10n.Expired.archiveAll : L10n.Expired.deleteAll)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(borderColor: Theme.Palette.danger.opacity(0.35))
    }

    private func expiredRow(_ medicine: Medicine) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: medicine) {
                HStack(spacing: 10) {
                    SymbolTile(
                        systemName: medicine.form.symbolName,
                        tint: Theme.Palette.danger,
                        size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(medicine.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Palette.ink)
                        Text(L10n.Expired.expiredOn(medicine.expiryDateText))
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.danger)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            Button {
                removeExpired([medicine])
            } label: {
                Image(systemName: subscriptionStore.isPro ? "archivebox.fill" : "trash.fill")
                    .foregroundStyle(Theme.Palette.danger)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                Text(subscriptionStore.isPro ? L10n.Expired.archiveOne : L10n.Common.delete))
        }
        .padding(10)
        .background(
            Theme.softBackground(Theme.Palette.danger),
            in: .rect(cornerRadius: 10))
    }

    private func removeExpired(_ medicines: [Medicine]) {
        if subscriptionStore.isPro {
            let result = MedicineActions.archive(medicines, reason: .expired, in: repository)
            if case .failure(.requiresPro) = result {
                appState.presentPaywall()
            }
        } else {
            medicinesPendingDeletion = medicines
        }
    }
}

#Preview {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return DashboardView()
        .environment(AppState())
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .modelContainer(container)
}

#Preview("Empty cabinet") {
    let container = PreviewData.emptyContainer
    let services = AppServices(modelContainer: container)
    return DashboardView()
        .environment(AppState())
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .modelContainer(container)
}
