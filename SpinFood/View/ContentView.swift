//
//  ContentView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @Environment(\.requestReview) var requestReview

    @Query var recipes: [RecipeModel]
    
    @State var store = Store()
    
    var hasActiveSubscription: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else if hasActiveSubscription {
            TabView {
                Tab("Summary", systemImage: "sparkles.rectangle.stack.fill") {
                    NavigationStack{
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
            .onAppear() {
                if recipes.count > 2 {
                    requestReview()
                }
            }
        } else {
            PaywallView()
        }
    }
}

#Preview {
    ContentView()
}
