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
    
    @State var isPresentingPaywall: Bool = false
    
    var hasActiveSubscription: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
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
            }
            .onAppear() {
                if recipes.count == 2 && !hasActiveSubscription {
                    isPresentingPaywall = true
                }
                
                if recipes.count > 2 {
                    requestReview()
                }
            }
            .fullScreenCover(isPresented: $isPresentingPaywall) {
                PaywallView()
            }
        }
    }
}

#Preview {
    ContentView()
}
