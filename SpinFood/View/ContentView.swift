//
//  ContentView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \RecipeModel.createdAt, order: .reverse) private var recipes: [RecipeModel]

    var body: some View {
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self, FoodRefillModel.self], inMemory: true)
}
