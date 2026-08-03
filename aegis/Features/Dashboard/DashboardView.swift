//
//  DashboardView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Ekran przeglądu: powitanie, trzy kafelki podsumowania, lista leków i panel
/// z lekami po terminie - układ przeniesiony z szablonu webowego.
struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(filter: MedicineQueries.active, sort: MedicineQueries.byExpiry)
    private var medicines: [Medicine]

    private let now = Date.now
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
        }
    }

    // MARK: - Nagłówek

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.Palette.ink)
            Text(L10n.Dashboard.subtitle)
                .font(.title3)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var greeting: LocalizedStringResource {
        switch Calendar.current.component(.hour, from: now) {
        case 5..<12: L10n.Dashboard.greetingMorning
        case 12..<18: L10n.Dashboard.greetingAfternoon
        default: L10n.Dashboard.greetingEvening
        }
    }

    // MARK: - Kafelki

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

    // MARK: - Panele

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
                    MedicineActions.archive(
                        expiredMedicines, reason: .expired, in: modelContext)
                } label: {
                    Text(L10n.Expired.archiveAll)
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
                MedicineActions.archive(medicine, reason: .expired, in: modelContext)
            } label: {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(Theme.Palette.danger)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(L10n.Expired.archiveOne))
        }
        .padding(10)
        .background(
            Theme.softBackground(Theme.Palette.danger),
            in: .rect(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .modelContainer(PreviewData.container)
}

#Preview("Pusta apteczka") {
    DashboardView()
        .environment(AppState())
        .modelContainer(PreviewData.emptyContainer)
}
