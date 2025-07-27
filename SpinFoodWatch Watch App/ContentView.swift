//
//  ContentView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI

struct ContentView: View {
    // TODO: implement a better storekit check
    var body: some View {
        TabView {
            StatsView()
            RecipeListView()
            FoodListView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self], inMemory: true)
}
