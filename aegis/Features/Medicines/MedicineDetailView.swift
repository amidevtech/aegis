//
//  MedicineDetailView.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Medicine details with actions: open package, edit, archive, and delete.
struct MedicineDetailView: View {
    @Bindable var medicine: Medicine

    @Environment(MedicineRepository.self) private var repository
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var isPresentingEditor = false
    @State private var isPresentingArchiveOptions = false
    @State private var isPresentingDeleteConfirm = false
    @State private var now = Date.now

    private var status: MedicineStatus { medicine.status(now: now) }

    private var openedBinding: Binding<Bool> {
        Binding(
            get: { medicine.isOpened },
            set: { MedicineActions.setOpened($0, for: medicine, in: repository) })
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
                    HStack(spacing: 6) {
                        Image(systemName: medicine.form.symbolName)
                        Text(medicine.form.label)
                    }
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
                    if subscriptionStore.isPro {
                        Button {
                            let result = MedicineActions.restore(medicine, in: repository)
                            if case .failure(.requiresPro) = result {
                                appState.presentPaywall()
                            }
                        } label: {
                            Label(L10n.Archive.restore, systemImage: "arrow.uturn.backward")
                        }

                        Button(role: .destructive) {
                            isPresentingDeleteConfirm = true
                        } label: {
                            Label(L10n.Common.delete, systemImage: "trash.fill")
                        }
                    }
                } else if subscriptionStore.isPro {
                    Button(role: .destructive) {
                        isPresentingArchiveOptions = true
                    } label: {
                        Label(L10n.Detail.archive, systemImage: "archivebox.fill")
                    }
                } else {
                    Button(role: .destructive) {
                        isPresentingDeleteConfirm = true
                    } label: {
                        Label(L10n.Common.delete, systemImage: "trash.fill")
                    }
                }
            } footer: {
                Text(subscriptionStore.isPro ? L10n.Expired.footnote : L10n.Medicines.deleteConfirmMessage)
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
                    let result = MedicineActions.archive(medicine, reason: reason, in: repository)
                    if case .failure(.requiresPro) = result {
                        appState.presentPaywall()
                    } else {
                        dismiss()
                    }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        }
        .confirmationDialog(
            Text(
                medicine.isArchived
                    ? L10n.Archive.deleteConfirmTitle
                    : L10n.Medicines.deleteConfirmTitle),
            isPresented: $isPresentingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.Common.delete, role: .destructive) {
                MedicineActions.delete(medicine, in: repository)
                dismiss()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(
                medicine.isArchived
                    ? L10n.Archive.deleteConfirmMessage
                    : L10n.Medicines.deleteConfirmMessage)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
    }

    // MARK: - Sections

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
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return NavigationStack {
        MedicineDetailView(medicine: PreviewData.samples[2])
    }
    .environment(AppState())
    .environment(services.subscriptionStore)
    .environment(services.repository)
    .modelContainer(container)
}
