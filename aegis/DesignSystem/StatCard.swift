//
//  StatCard.swift
//  aegis
//

import SwiftUI

/// Kafelek podsumowania z ekranu przeglądu - odpowiednik `.stats article` z szablonu.
struct StatCard: View {
    let title: LocalizedStringResource
    let caption: LocalizedStringResource
    let value: Int
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                SymbolTile(systemName: systemImage, tint: tint, size: 54)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(value, format: .number)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                        .contentTransition(.numericText())
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Palette.muted)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(cornerRadius: Theme.Metrics.tileCornerRadius, padding: 16)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Kafelki") {
    VStack(spacing: 12) {
        StatCard(
            title: L10n.Dashboard.statActiveTitle,
            caption: L10n.Dashboard.statActiveCaption,
            value: 12,
            systemImage: "cross.case.fill",
            tint: Theme.Palette.brandDeep,
            action: {})
        StatCard(
            title: L10n.Dashboard.statOpenedTitle,
            caption: L10n.Dashboard.statOpenedCaption,
            value: 3,
            systemImage: "checkmark.seal.fill",
            tint: Theme.Palette.opened,
            action: {})
        StatCard(
            title: L10n.Dashboard.statExpiringTitle,
            caption: L10n.Dashboard.statExpiringCaption,
            value: 2,
            systemImage: "clock.badge.exclamationmark.fill",
            tint: Theme.Palette.warning,
            action: {})
    }
    .padding()
    .background(Theme.Palette.canvas)
}
