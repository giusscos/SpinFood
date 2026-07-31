//
//  PaywallLifetimeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 19/07/25.
//

import StoreKit
import SwiftUI

struct PaywallLifetimeView: View {
    var onPurchase: () -> Void = {}
    @Environment(Store.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "infinity.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text("Lifetime Access")
                    .font(.title3.bold())

                Text("Pay once, cook forever.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("No recurring charges, ever.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 28)
            .padding(.horizontal)
            .padding(.bottom, 4)

            StoreView(ids: store.productLifetimeIds) { _ in }
                .padding(.vertical)
                .padding(.horizontal, 8)
                .productViewStyle(.compact)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .cancellation)
                .onInAppPurchaseCompletion { _, result in
                    if case .success(let purchaseResult) = result,
                       case .success(let verification) = purchaseResult {
                        Task {
                            await store.handlePurchaseSuccess(verification)
                            onPurchase()
                        }
                    }
                }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PaywallLifetimeView()
        .environment(Store())
}
