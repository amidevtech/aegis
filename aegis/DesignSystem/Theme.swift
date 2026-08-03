//
//  Theme.swift
//  aegis
//

import SwiftUI

/// Shared palette and metrics for every screen.
/// Colors come from the web template and include dark-mode variants.
///
/// The type stays main-actor bound on purpose — color symbols generated
/// from the asset catalog are main-actor too.
enum Theme {

    enum Palette {
        static let brand = Color(.brandPrimary)
        static let brandDeep = Color(.brandDeep)
        static let ink = Color(.ink)
        static let muted = Color(.muted)
        static let outline = Color(.outline)
        static let canvas = Color(.canvas)
        static let surface = Color(.surface)
        static let danger = Color(.danger)
        static let opened = Color(.opened)
        static let warning = Color(.warning)
    }

    enum Metrics {
        static let cardCornerRadius: CGFloat = 16
        static let tileCornerRadius: CGFloat = 13
        static let symbolCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 18
        static let sectionSpacing: CGFloat = 18
        static let symbolSize: CGFloat = 46
    }

    /// Soft accent-tinted background under an icon, matching `.medicine-symbol` in the template.
    static func softBackground(_ color: Color) -> Color {
        color.opacity(0.14)
    }
}

extension MedicineStatus {
    var tint: Color {
        switch self {
        case .valid: Theme.Palette.opened
        case .expiringSoon: Theme.Palette.warning
        case .expired: Theme.Palette.danger
        }
    }
}
