//
//  PaywallLifetimeView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 19/07/25.
//

import StoreKit
import SwiftUI

struct PaywallLifetimeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var storeKit = Store()
    
    var body: some View {
        StoreView(ids: storeKit.productLifetimeIds) { product in
//            Image("paywall-lifetime")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 60, height: 60)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical)
        .padding(.horizontal, 8)
        .productViewStyle(.compact)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PaywallLifetimeView()
}
