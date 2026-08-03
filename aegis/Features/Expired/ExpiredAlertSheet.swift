//
//  ExpiredAlertSheet.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Sheet shown at app launch when the cabinet has expired medicines.
struct ExpiredAlertSheet: View {
    let medicines: [Medicine]

    @Environment(\.dismiss) private var dismiss
    @Environment(MedicineRepository.self) private var repository
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(AppState.self) private var appState

    @State private var pendingDeleteAll = false
    @State private var handledUUIDs: Set<UUID> = []

    private var remainingMedicines: [Medicine] {
        medicines.filter { !handledUUIDs.contains($0.uuid) && !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    banner

                    VStack(spacing: 10) {
                        ForEach(remainingMedicines, id: \.uuid) { medicine in
                            row(medicine)
                        }
                    }

                    Text(subscriptionStore.isPro ? L10n.Expired.footnote : L10n.Medicines.deleteConfirmMessage)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.canvas)
            .navigationTitle(Text(L10n.Expired.title))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Expired.later) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        subscriptionStore.isPro ? L10n.Expired.archiveAll : L10n.Expired.deleteAll,
                        action: handleAll
                    )
                    .disabled(remainingMedicines.isEmpty)
                }
            }
            .confirmationDialog(
                Text(L10n.Medicines.deleteConfirmTitle),
                isPresented: $pendingDeleteAll,
                titleVisibility: .visible
            ) {
                Button(L10n.Common.delete, role: .destructive) {
                    for medicine in remainingMedicines {
                        MedicineActions.delete(medicine, in: repository)
                    }
                    dismiss()
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Medicines.deleteConfirmMessage)
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 460)
        #endif
    }

    private var banner: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38))
                .foregroundStyle(Theme.Palette.danger)

            Text(L10n.Expired.message(remainingMedicines.count))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card(borderColor: Theme.Palette.danger.opacity(0.35))
    }

    private func row(_ medicine: Medicine) -> some View {
        HStack(spacing: 12) {
            SymbolTile(
                systemName: medicine.form.symbolName,
                tint: Theme.Palette.danger,
                size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(medicine.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)

                Text(L10n.Expired.expiredOn(medicine.expiryDateText))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.danger)

                if let meta = medicine.metaText {
                    Text(meta)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }

            Spacer(minLength: 8)

            Button {
                withAnimation(.snappy) {
                    handleOne(medicine)
                }
            } label: {
                Label(
                    subscriptionStore.isPro ? L10n.Expired.archiveOne : L10n.Common.delete,
                    systemImage: subscriptionStore.isPro ? "archivebox.fill" : "trash.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .tint(Theme.Palette.danger)
        }
        .padding(12)
        .card(cornerRadius: 12, padding: 0, borderColor: Theme.Palette.danger.opacity(0.3))
    }

    private func handleAll() {
        if subscriptionStore.isPro {
            let result = MedicineActions.archive(remainingMedicines, reason: .expired, in: repository)
            if case .failure(.requiresPro) = result {
                appState.presentPaywall()
            } else {
                dismiss()
            }
        } else {
            pendingDeleteAll = true
        }
    }

    private func handleOne(_ medicine: Medicine) {
        if subscriptionStore.isPro {
            let result = MedicineActions.archive(medicine, reason: .expired, in: repository)
            if case .failure(.requiresPro) = result {
                appState.presentPaywall()
                return
            }
            handledUUIDs.insert(medicine.uuid)
            if remainingMedicines.isEmpty { dismiss() }
        } else {
            MedicineActions.delete(medicine, in: repository)
            handledUUIDs.insert(medicine.uuid)
            if remainingMedicines.isEmpty { dismiss() }
        }
    }
}

#Preview {
    let container = PreviewData.container
    let services = AppServices(modelContainer: container)
    return ExpiredAlertSheet(medicines: PreviewData.samples.filter { $0.status() == .expired })
        .environment(AppState())
        .environment(services.subscriptionStore)
        .environment(services.repository)
        .modelContainer(container)
}
