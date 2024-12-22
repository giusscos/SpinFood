//
//  Store.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import Foundation
import StoreKit

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo //The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState // the renewal states of auto-renewable subscriptions.

@Observable
class Store {
    private var subscriptions: [Product] = []
    var purchasedSubscriptions: [Product] = []
    private var subscriptionGroupStatus: RenewalState?
    
    private let productIds: [String] = ["Wiiyf_999_1y_3d", "Wiiyf_099_1m_3d"]
    let groupId: String = "21611710"
    
//    private let productIds: [String] = ["sf_999_1y", "sp_099_1m_3d"] // test
//    let groupId: String = "FE73F688" // test
    
    var updateListenerTask : Task<Void, Error>? = nil
    
    init() {
        //start a transaction listern as close to app launch as possible so you don't miss a transaction
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // deliver products to the user
                    await self.updateCustomerProductStatus()
                    
                    await transaction.finish()
                } catch {
                    print("transaction failed verification")
                }
            }
        }
    }
    
    // Request the products
    @MainActor
    func requestProducts() async {
        do {
            // request from the app store using the product ids (hardcoded)
            subscriptions = try await Product.products(for: productIds)
            print(subscriptions)
        } catch {
            print("Failed product request from app store server: \(error)")
        }
    }
    
    // purchase the product
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)
            
            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()
            
            //Always finish a transaction.
            await transaction.finish()
            
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
                //Always finish a transaction.
                await transaction.finish()
            } catch {
                print("failed updating products")
            }
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}
