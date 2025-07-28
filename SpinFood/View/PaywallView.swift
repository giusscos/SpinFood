//
//  PaywallView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @State var store = Store()
    
    @State private var showLifetimePlans: Bool = false
    
    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: store.groupId) {
                VStack {
                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label("Save with lifetime plans", systemImage: "sparkle")
                            .font(.headline)
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding(.vertical)
                    
                    VStack {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.linearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .trailing))
                        
                        Text("Foo+")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Add your personal recipes, get personalized recipe suggestions, and track your food waste.")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "chart.pie.fill", color: .purple, text: "Advanced recipe statistics")
                        FeatureRow(icon: "fork.knife", color: .indigo, text: "Smart ingredient-based suggestions")
                        FeatureRow(icon: "leaf.fill", color: .green, text: "Food waste reduction tracking")
                    }
                    .padding()
                    
                    HStack {
                        Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                        
                        Text("and")
                            .foregroundStyle(.secondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                    }
                    .font(.caption)
                }
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .interactiveDismissDisabled()
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView()
                    .presentationDetents(.init([.medium]))
            }
        }
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
