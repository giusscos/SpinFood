//
//  ContentView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
            
            FoodListView()
                .tabItem {
                    Label("Food", systemImage: "carrot.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self, RecipeFoodModel.self], inMemory: true)
}
