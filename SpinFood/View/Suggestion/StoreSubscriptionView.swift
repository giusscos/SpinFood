//
//  StoreSubscriptionView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import SwiftUI
import StoreKit

struct StoreSubscriptionView: View {
    
    var body: some View {
        SubscriptionStoreView(groupID: Store().groupId) {
            LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottom)
                .overlay {
                    VStack {
                        Text("SpinFood Pro Access")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Unlock recipe suggestions designed to help you minimize food waste. You will get meal ideas based on your remaining food and also gain access to upcoming analytics to track the recipes you’ve tried and the food you’ve consumed.")
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
        }
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .policies)
        .storeButton(.visible, for: .redeemCode)
    }
}

#Preview {
    StoreSubscriptionView()
}
