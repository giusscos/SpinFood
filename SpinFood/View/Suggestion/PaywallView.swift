//
//  PaywallView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State var store: Store
    
    var body: some View {
        SubscriptionStoreView(groupID: store.groupId) {
            //                LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottom)
            //                    .overlay {
            //                        VStack {
            //                            Text("Unlock Pro Features")
            //                                .font(.headline)
            //                                .fontWeight(.bold)
            //
            //                            Text("Get personalized recipe suggestions based on your inventory and track your cooking habits with detailed statistics.")
            //                                .multilineTextAlignment(.center)
            //                                .font(.subheadline)
            //                        }
            //                        .foregroundStyle(.white)
            //                        .padding()
            //                    }
            VStack {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 60))
                        .foregroundStyle(.linearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing))
                        .padding(.bottom, 5)
                    
                    Text("SpinFood Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock All Statistics & Suggestions")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Features
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "chart.pie.fill", color: .purple, text: "Advanced recipe statistics")
                    FeatureRow(icon: "fork.knife", color: .indigo, text: "Smart ingredient-based suggestions")
                    FeatureRow(icon: "leaf.fill", color: .green, text: "Food waste reduction tracking")
                    FeatureRow(icon: "calendar", color: .orange, text: "Meal planning capabilities")
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .redeemCode)
        .padding(.horizontal)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    PaywallView(store: Store())
}
