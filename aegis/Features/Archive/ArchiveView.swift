//
//  ArchiveView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Historia apteczki. Leki tu trafiają zamiast być kasowane, więc zawsze wiadomo,
/// co i komu było kiedyś przepisane. Trwałe usunięcie jest możliwe tylko stąd.
struct ArchiveView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: MedicineQueries.archived, sort: MedicineQueries.byArchiveDate)
    private var medicines: [Medicine]

    @State private var searchText = ""
    @State private var medicinePendingDeletion: Medicine?

    private var visibleMedicines: [Medicine] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return medicines }
        return medicines.filter { $0.matches(freeText: query) }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text(L10n.Archive.title))
                .navigationDestination(for: Medicine.self) { medicine in
                    MedicineDetailView(medicine: medicine)
                }
                .searchable(text: $searchText, prompt: Text(L10n.Archive.searchPrompt))
                .confirmationDialog(
                    Text(L10n.Archive.deleteConfirmTitle),
                    isPresented: deletionDialogBinding,
                    titleVisibility: .visible,
                    presenting: medicinePendingDeletion
                ) { medicine in
                    Button(L10n.Common.delete, role: .destructive) {
                        MedicineActions.deletePermanently(medicine, in: modelContext)
                        medicinePendingDeletion = nil
                    }
                    Button(L10n.Common.cancel, role: .cancel) {
                        medicinePendingDeletion = nil
                    }
                } message: { _ in
                    Text(L10n.Archive.deleteConfirmMessage)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if medicines.isEmpty {
            EmptyStateView(
                systemImage: "archivebox",
                title: L10n.Archive.emptyTitle,
                message: L10n.Archive.emptyMessage)
                .background(Theme.Palette.canvas)
        } else if visibleMedicines.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: L10n.Medicines.noResultsTitle,
                message: L10n.Medicines.noResultsMessage)
                .background(Theme.Palette.canvas)
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(visibleMedicines, id: \.uuid) { medicine in
                    NavigationLink(value: medicine) {
                        row(medicine)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            medicinePendingDeletion = medicine
                        } label: {
                            Label(L10n.Common.delete, systemImage: "trash.fill")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            MedicineActions.restore(medicine, in: modelContext)
                        } label: {
                            Label(L10n.Archive.restore, systemImage: "arrow.uturn.backward")
                        }
                        .tint(Theme.Palette.brand)
                    }
                }
            } header: {
                Text(L10n.Archive.subtitle)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.canvas)
    }

    private func row(_ medicine: Medicine) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolTile(
                systemName: medicine.form.symbolName,
                tint: Theme.Palette.muted)

            VStack(alignment: .leading, spacing: 3) {
                Text(medicine.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)

                if let subtitle = medicine.subtitleText {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }

                if let meta = medicine.metaText {
                    Text(meta)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                if let reason = medicine.archiveReason {
                    StatusTag(
                        text: reason.label,
                        tint: Theme.Palette.muted,
                        systemImage: reason.symbolName)
                }
                if let archivedAtText = medicine.archivedAtText {
                    Text(archivedAtText)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var deletionDialogBinding: Binding<Bool> {
        Binding(
            get: { medicinePendingDeletion != nil },
            set: { if !$0 { medicinePendingDeletion = nil } })
    }
}

#Preview {
    ArchiveView()
        .modelContainer(PreviewData.container)
}
