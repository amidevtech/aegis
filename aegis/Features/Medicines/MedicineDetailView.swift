//
//  MedicineDetailView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Szczegóły leku wraz z akcjami: otwarcie opakowania, edycja i archiwizacja.
struct MedicineDetailView: View {
    @Bindable var medicine: Medicine

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingEditor = false
    @State private var isPresentingArchiveOptions = false

    private let now = Date.now

    private var status: MedicineStatus { medicine.status(now: now) }

    private var openedBinding: Binding<Bool> {
        Binding(
            get: { medicine.isOpened },
            set: { MedicineActions.setOpened($0, for: medicine, in: modelContext) })
    }

    var body: some View {
        Form {
            Section {
                header
            }

            Section(L10n.Form.sectionPrescription) {
                labeled(L10n.Detail.person, value: medicine.personName)
                labeled(L10n.Detail.indication, value: medicine.indication)
                labeled(L10n.Detail.dosage, value: medicine.dosage)
            }

            Section(L10n.Form.sectionMedicine) {
                LabeledContent {
                    Label(medicine.form.label, systemImage: medicine.form.symbolName)
                        .foregroundStyle(Theme.Palette.ink)
                } label: {
                    Text(L10n.Detail.form)
                }
                labeled(L10n.Detail.quantity, value: medicine.quantity)
            }

            expirySection

            if !medicine.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                Section(L10n.Detail.notes) {
                    Text(medicine.notes)
                        .foregroundStyle(Theme.Palette.ink)
                }
            }

            Section {
                if medicine.isArchived {
                    Button {
                        MedicineActions.restore(medicine, in: modelContext)
                    } label: {
                        Label(L10n.Archive.restore, systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button(role: .destructive) {
                        isPresentingArchiveOptions = true
                    } label: {
                        Label(L10n.Detail.archive, systemImage: "archivebox.fill")
                    }
                }
            } footer: {
                Text(L10n.Expired.footnote)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(medicine.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingEditor = true
                } label: {
                    Label(L10n.Common.edit, systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $isPresentingEditor) {
            MedicineFormView(mode: .edit(medicine))
        }
        .confirmationDialog(
            Text(L10n.Detail.archiveTitle),
            isPresented: $isPresentingArchiveOptions,
            titleVisibility: .visible
        ) {
            ForEach(ArchiveReason.allCases) { reason in
                Button(reason.label) {
                    MedicineActions.archive(medicine, reason: reason, in: modelContext)
                    dismiss()
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        }
    }

    // MARK: - Sekcje

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            SymbolTile(
                systemName: medicine.form.symbolName,
                tint: status.tint,
                size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.name)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.Palette.ink)

                if !medicine.activeSubstance.isEmpty {
                    Text(medicine.activeSubstance)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.muted)
                }

                HStack(spacing: 8) {
                    StatusTag(
                        text: status.label,
                        tint: status.tint,
                        systemImage: status.symbolName)

                    if medicine.isOpened {
                        StatusTag(
                            text: L10n.Status.opened,
                            tint: Theme.Palette.opened,
                            systemImage: "checkmark.seal.fill")
                    }
                }

                Text(medicine.expiryDescription(now: now))
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
        .padding(.vertical, 4)
    }

    private var expirySection: some View {
        Section(L10n.Form.sectionExpiry) {
            LabeledContent {
                Text(medicine.packageExpiryDateText)
            } label: {
                Text(L10n.Detail.expiry)
            }

            Toggle(isOn: openedBinding) {
                Label(L10n.Form.opened, systemImage: "checkmark.seal.fill")
            }
            .tint(Theme.Palette.opened)

            if medicine.isOpened {
                if let openedAtText = medicine.openedAtText {
                    LabeledContent {
                        Text(openedAtText)
                    } label: {
                        Text(L10n.Detail.openedAt)
                    }
                }

                if let openedExpiry = medicine.openedExpiryDateText {
                    LabeledContent {
                        Text(openedExpiry)
                    } label: {
                        Text(L10n.Detail.openedExpiry)
                    }
                }
            }

            LabeledContent {
                Text(medicine.expiryDateText)
                    .foregroundStyle(status.tint)
                    .fontWeight(.semibold)
            } label: {
                Text(L10n.Detail.effectiveExpiry)
            }

            if medicine.isArchived, let reason = medicine.archiveReason,
               let archivedAtText = medicine.archivedAtText {
                LabeledContent {
                    Text(archivedAtText)
                } label: {
                    Label(reason.label, systemImage: reason.symbolName)
                }
            }

            LabeledContent {
                Text(medicine.createdAtText)
            } label: {
                Text(L10n.Detail.added)
            }
        }
    }

    @ViewBuilder
    private func labeled(_ label: LocalizedStringResource, value: String) -> some View {
        LabeledContent {
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(L10n.Common.notProvided)
                    .foregroundStyle(Theme.Palette.muted)
            } else {
                Text(value)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.trailing)
            }
        } label: {
            Text(label)
        }
    }
}

#Preview {
    NavigationStack {
        MedicineDetailView(medicine: PreviewData.samples[2])
    }
    .modelContainer(PreviewData.container)
}
