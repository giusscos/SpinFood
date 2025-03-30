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
    @State private var hasMigratedSteps = false
    
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
        .onAppear {
            // Migrate old string steps to new array-based steps if needed
            migrateSteps()
        }
    }
    
    private func migrateSteps() {
        // Only run this once
        if hasMigratedSteps {
            return
        }
        
        hasMigratedSteps = true
        
        // Check for any legacy recipes that might need migration
        for recipe in recipes {
            // If stepInstructions is empty, look for legacy steps
            if recipe.stepInstructions.isEmpty {
                if let legacySteps = getMigrateSteps(recipe: recipe) {
                    recipe.stepInstructions = legacySteps
                    // Create empty image placeholders for each step
                    recipe.stepImages = Array(repeating: nil, count: legacySteps.count)
                }
            }
        }
    }
    
    // This function would be implemented to access any legacy steps
    private func getMigrateSteps(recipe: RecipeModel) -> [String]? {
        // Access any legacy step storage format you might have
        // Return nil if no legacy steps exist
        return nil
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self, FoodRefillModel.self], inMemory: true)
}
