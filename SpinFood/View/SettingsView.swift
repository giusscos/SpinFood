//
//  SettingsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @State var store = Store()
    
    @State var manageSubscription: Bool = false
    
    var body: some View {
        List {
            Section {
                if !store.purchasedSubscriptions.isEmpty {
                    Button("Manage subscription") {
                        manageSubscription.toggle()
                    }
                }
                    
                Link("Send me a Feedback", destination: URL(string: "mailto:hello@giusscos.com")!)
                    .foregroundColor(.blue)
                
                Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .foregroundColor(.blue)
                
                Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                    .foregroundColor(.blue)
            } header: {
                Text("Support")
            }
        }.manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: Store().groupId)
    }
}

#Preview {
    SettingsView()
}
