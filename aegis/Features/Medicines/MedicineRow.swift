//
//  MedicineRow.swift
//  aegis
//

import SwiftUI

/// Wiersz listy leków - odpowiednik `.medicine-row` z szablonu webowego.
struct MedicineRow: View {
    let medicine: Medicine
    var now: Date = .now

    private var status: MedicineStatus { medicine.status(now: now) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolTile(systemName: medicine.form.symbolName, tint: status.tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(medicine.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)

                if let subtitle = medicine.subtitleText {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }

                if let meta = medicine.metaText {
                    Text(meta)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.brandDeep)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                StatusTag(text: status.label, tint: status.tint, systemImage: status.symbolName)

                Text(medicine.expiryDescription(now: now))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.trailing)

                if medicine.isOpened {
                    Label {
                        Text(L10n.Status.opened)
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.Palette.opened)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Wiersze") {
    List(PreviewData.samples.prefix(5), id: \.uuid) { medicine in
        MedicineRow(medicine: medicine)
    }
}
