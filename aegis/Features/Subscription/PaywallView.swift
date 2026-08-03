//
//  PaywallView.swift
//  aegis
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    benefits
                    plans
                    if let message = subscriptionStore.lastErrorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.danger)
                    }
                    restoreButton
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.canvas)
            .navigationTitle(Text(L10n.Paywall.title))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
            .task {
                await subscriptionStore.loadProducts()
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 520)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Paywall.headline)
                .font(.title.bold())
                .foregroundStyle(Theme.Palette.ink)
            Text(L10n.Paywall.subtitle)
                .font(.body)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 10) {
            benefitRow(systemImage: "icloud.fill", text: L10n.Paywall.benefitSync)
            benefitRow(systemImage: "person.3.fill", text: L10n.Paywall.benefitFamily)
            benefitRow(systemImage: "archivebox.fill", text: L10n.Paywall.benefitArchive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func benefitRow(systemImage: String, text: LocalizedStringResource) -> some View {
        Label {
            Text(text)
                .foregroundStyle(Theme.Palette.ink)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Palette.brandDeep)
        }
        .font(.subheadline)
    }

    private var plans: some View {
        VStack(spacing: 12) {
            if subscriptionStore.isLoading && subscriptionStore.products.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }

            ForEach(subscriptionStore.products, id: \.id) { product in
                Button {
                    Task {
                        if await subscriptionStore.purchase(product) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(Theme.Palette.muted)
                        }
                        Spacer()
                        Text(product.displayPrice)
                            .font(.headline)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Palette.surface, in: .rect(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.Palette.outline, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .disabled(subscriptionStore.isLoading)
            }

            #if DEBUG
            Button(L10n.Paywall.debugUnlock) {
                subscriptionStore.debugProOverride = true
                dismiss()
            }
            .buttonStyle(.bordered)
            #endif
        }
    }

    private var restoreButton: some View {
        Button(L10n.Paywall.restore) {
            Task { await subscriptionStore.restore() }
        }
        .frame(maxWidth: .infinity)
        .disabled(subscriptionStore.isLoading)
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionStore())
}
