//
//  CardBackground.swift
//  aegis
//

import SwiftUI

/// White card with border and soft shadow — counterpart of the web template panels.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = Theme.Metrics.cardCornerRadius
    var padding: CGFloat = Theme.Metrics.cardPadding
    var borderColor: Color = Theme.Palette.outline

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .shadow(color: Theme.Palette.ink.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func card(
        cornerRadius: CGFloat = Theme.Metrics.cardCornerRadius,
        padding: CGFloat = Theme.Metrics.cardPadding,
        borderColor: Color = Theme.Palette.outline
    ) -> some View {
        modifier(CardBackground(
            cornerRadius: cornerRadius,
            padding: padding,
            borderColor: borderColor))
    }
}

/// Square icon on a soft tinted background, used on medicine rows and stat tiles.
struct SymbolTile: View {
    let systemName: String
    var tint: Color = Theme.Palette.brand
    var size: CGFloat = Theme.Metrics.symbolSize

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                Theme.softBackground(tint),
                in: .rect(cornerRadius: Theme.Metrics.symbolCornerRadius))
            .accessibilityHidden(true)
    }
}

/// Rounded status badge, counterpart of `.tag` in the template.
struct StatusTag: View {
    let text: LocalizedStringResource
    let tint: Color
    var systemImage: String?

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.softBackground(tint), in: .capsule)
    }
}

#Preview("Cards and badges") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            SymbolTile(systemName: "pills.fill")
            SymbolTile(systemName: "drop.fill", tint: Theme.Palette.opened)
            SymbolTile(systemName: "syringe.fill", tint: Theme.Palette.warning)
        }
        HStack(spacing: 8) {
            StatusTag(text: L10n.Status.valid, tint: Theme.Palette.opened,
                      systemImage: "checkmark.circle.fill")
            StatusTag(text: L10n.Status.expiringSoon, tint: Theme.Palette.warning,
                      systemImage: "clock.fill")
            StatusTag(text: L10n.Status.expired, tint: Theme.Palette.danger,
                      systemImage: "exclamationmark.triangle.fill")
        }
        Text("Karta")
            .frame(maxWidth: .infinity)
            .card()
    }
    .padding()
    .background(Theme.Palette.canvas)
}
