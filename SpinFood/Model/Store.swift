//
//  Store.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import Foundation
import StoreKit

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

@Observable
final class Store {
    private var subscriptions: [Product] = []
    private var storeProducts: [Product] = []

    /// Product IDs with an active entitlement (subscriptions + lifetime).
    private(set) var purchasedSubscriptionIDs: Set<String> = []
    private(set) var purchasedLifetimeIDs: Set<String> = []

    var purchasedSubscriptions: [Product] {
        subscriptions.filter { purchasedSubscriptionIDs.contains($0.id) }
    }

    var purchasedProducts: [Product] {
        storeProducts.filter { purchasedLifetimeIDs.contains($0.id) }
    }

    private var subscriptionGroupStatus: RenewalState?
    var isLoading: Bool = true

    var hasActiveSubscription: Bool {
        !purchasedSubscriptionIDs.isEmpty || !purchasedLifetimeIDs.isEmpty
    }

    let productIds: [String] = ["f_199_1w", "f_999_1y_1w", "f_fa_2999_1y_1w"]
    let groupId: String = "21742027"
    let productLifetimeIds: [String] = ["com.giusscos.fooFamilyLifetime", "com.giusscos.fooLifetime"]

    private var updateListenerTask: Task<Void, Error>? = nil

    init() {
        updateListenerTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
            isLoading = false
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("transaction failed verification")
                }
            }
        }
    }

    @MainActor
    func requestProducts() async {
        do {
            storeProducts = try await Product.products(for: productLifetimeIds)
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }

    func isPurchased(_ product: Product) async throws -> Bool {
        purchasedLifetimeIDs.contains(product.id) || purchasedSubscriptionIDs.contains(product.id)
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// Immediately unlocks from a verified purchase, then reconciles with current entitlements.
    @MainActor
    func handlePurchaseSuccess(_ verification: VerificationResult<Transaction>) async {
        var grantedSubscriptionID: String?
        var grantedLifetimeID: String?

        do {
            let transaction = try checkVerified(verification)
            switch transaction.productType {
            case .autoRenewable:
                grantedSubscriptionID = transaction.productID
                purchasedSubscriptionIDs.insert(transaction.productID)
            case .nonConsumable:
                if productLifetimeIds.contains(transaction.productID) {
                    grantedLifetimeID = transaction.productID
                    purchasedLifetimeIDs.insert(transaction.productID)
                }
            default:
                break
            }
            await transaction.finish()
        } catch {
            print("purchase verification failed")
        }

        await updateCustomerProductStatus()

        // StoreKit can lag briefly; keep the just-purchased entitlement unlocked.
        if let grantedSubscriptionID {
            purchasedSubscriptionIDs.insert(grantedSubscriptionID)
        }
        if let grantedLifetimeID {
            purchasedLifetimeIDs.insert(grantedLifetimeID)
        }
    }

    /// Re-reads StoreKit entitlements and updates Pro status.
    /// Matches by product ID so unlock works even before `Product` objects finish loading.
    @MainActor
    func updateCustomerProductStatus() async {
        var subscriptionIDs: Set<String> = []
        var lifetimeIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                switch transaction.productType {
                case .autoRenewable:
                    // currentEntitlements only yields active entitlements for this app.
                    subscriptionIDs.insert(transaction.productID)
                case .nonConsumable:
                    if productLifetimeIds.contains(transaction.productID) {
                        lifetimeIDs.insert(transaction.productID)
                    }
                default:
                    break
                }
            } catch {
                print("failed updating products")
            }
        }

        purchasedSubscriptionIDs = subscriptionIDs
        purchasedLifetimeIDs = lifetimeIDs
    }
}

public enum StoreError: Error {
    case failedVerification
}
