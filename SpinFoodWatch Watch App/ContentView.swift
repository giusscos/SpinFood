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
    var body: some View {
//        if syncManager.hasActiveSubscription {
            TabView {
                StatsView()
                RecipeListView()
                FoodListView()
            }
//        } else {
//            Text("Subscribe or buy lifetime access on the iPhone app")
//                .padding()
//                .multilineTextAlignment(.center)
//        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self], inMemory: true)
}
