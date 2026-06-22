//
//  PaywallLifetimeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 19/07/25.
//

import StoreKit
import SwiftUI

struct PaywallLifetimeView: View {
    @State var storeKit = Store()

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

                Text("Pay once, cook forever.\nNo recurring charges, ever.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.horizontal)
            .padding(.bottom, 4)

            StoreView(ids: storeKit.productLifetimeIds) { _ in }
                .padding(.vertical)
                .padding(.horizontal, 8)
                .productViewStyle(.compact)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .cancellation)
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PaywallLifetimeView()
}
