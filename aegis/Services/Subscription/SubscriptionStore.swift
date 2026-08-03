//
//  SubscriptionStore.swift
//  aegis
//

import Foundation
import Observation
import StoreKit

/// Stan subskrypcji Pro. Gate dla CloudSync, archiwum i udostępniania rodziny.
@MainActor
@Observable
final class SubscriptionStore {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var lastErrorMessage: String?

    /// Lokalny override do testów (Configuration.storekit / UI bez ASC).
    /// Nie jest persystowany — żeby testy i debug nie zostawiały stanu między uruchomieniami procesu.
    var debugProOverride: Bool?

    var isPro: Bool {
        if let debugProOverride { return debugProOverride }
        return !purchasedProductIDs.isEmpty
    }

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {}

    func startListeningForTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            products = try await Product.products(for: SubscriptionProductID.allIDs)
                .sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                return true
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate == nil {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
