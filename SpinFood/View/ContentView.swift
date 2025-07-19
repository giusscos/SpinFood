//
//  ContentView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State var store = Store()
    
    var hasActiveSubscription: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            if store.isLoading {
                ProgressView()
            } else if hasActiveSubscription {
                TabView {
                    Tab("Summary", systemImage: "sparkles.rectangle.stack.fill") {
                        NavigationStack {
                            SummaryView()
                        }
                    }
                    
                    Tab("Recipes", systemImage: "fork.knife") {
                        NavigationStack {
                            RecipeView()
                        }
                    }
                    
                    Tab("Food", systemImage: "carrot.fill") {
                        NavigationStack {
                            FoodView()
                        }
                    }
                    
                    Tab("Settings", systemImage: "gear") {
                        NavigationStack {
                            SettingsView()
                        }
                    }
                }
            } else {
                PaywallView()
            }
        }
    }
}

#Preview {
    ContentView()
}
