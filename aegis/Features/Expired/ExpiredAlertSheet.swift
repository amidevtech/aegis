//
//  ExpiredAlertSheet.swift
//  aegis
//

import SwiftData
import SwiftUI

/// Arkusz pokazywany przy starcie aplikacji, gdy w apteczce są leki po terminie.
///
/// Jedyną akcją "usuwającą" jest archiwizacja - lek znika z apteczki, ale zostaje
/// w historii jako informacja, że kiedyś był przepisany.
struct ExpiredAlertSheet: View {
    let medicines: [Medicine]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    banner

                    VStack(spacing: 10) {
                        ForEach(medicines, id: \.uuid) { medicine in
                            row(medicine)
                        }
                    }

                    Text(L10n.Expired.footnote)
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
                    Button(L10n.Expired.archiveAll, action: archiveAll)
                        .disabled(medicines.isEmpty)
                }
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

            Text(L10n.Expired.message(medicines.count))
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
                    MedicineActions.archive(medicine, reason: .expired, in: modelContext)
                }
                dismissIfHandled()
            } label: {
                Label(L10n.Expired.archiveOne, systemImage: "archivebox.fill")
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

    private func archiveAll() {
        MedicineActions.archive(medicines, reason: .expired, in: modelContext)
        dismiss()
    }

    /// Gdy archiwizacja objęła ostatni lek, nie ma już czego pokazywać.
    private func dismissIfHandled() {
        if medicines.allSatisfy(\.isArchived) {
            dismiss()
        }
    }
}

#Preview {
    ExpiredAlertSheet(medicines: PreviewData.samples.filter { $0.status() == .expired })
        .modelContainer(PreviewData.container)
}
