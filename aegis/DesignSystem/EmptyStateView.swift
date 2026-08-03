//
//  EmptyStateView.swift
//  aegis
//

import SwiftUI

/// Empty state built on system `ContentUnavailableView`, with an optional action.
struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    var actionTitle: LocalizedStringResource?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    EmptyStateView(
        systemImage: "cross.case",
        title: L10n.Dashboard.emptyTitle,
        message: L10n.Dashboard.emptyMessage,
        actionTitle: L10n.Medicines.add) {}
}
