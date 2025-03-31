//
//  ContentView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @State private var store = Store()
    
    var hasActiveSubscription: Bool {
        !store.purchasedSubscriptions.isEmpty
    }
    
    var body: some View {
        TabView {
//            Group {
//                if store.isLoading {
//                    LoadingView()
//                } else if hasActiveSubscription {
//                    StatsView()
//                } else {
//                    PremiumPromptView(store: store)
//                }
//            }
//            .tabItem {
//                Text("Stats")
//            }
            
            RecipeListView()
                .tabItem {
                    Text("Recipes")
                }
            
            FoodListView()
                .tabItem {
                    Text("Food")
                }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            
            Text("Checking subscription status...")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct PremiumPromptView: View {
    @State private var isRefreshing = false
    var store: Store
    
    var body: some View {
        VStack {
            Label("Unlock premium", systemImage: "lock.fill")
            
            Text("Subscribe in the iPhone app to access statistics on your watch")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self, RecipeFoodModel.self], inMemory: true)
}
