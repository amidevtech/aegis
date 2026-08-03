//
//  Theme.swift
//  aegis
//

import SwiftUI

/// Paleta i metryki wspólne dla wszystkich ekranów.
/// Kolory pochodzą z szablonu webowego i mają warianty dla trybu ciemnego.
///
/// Typ celowo pozostaje związany z głównym aktorem - symbole kolorów generowane
/// z katalogu zasobów też takie są.
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

    /// Delikatne tło pod ikoną w kolorze akcentu, tak jak `.medicine-symbol` w szablonie.
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
