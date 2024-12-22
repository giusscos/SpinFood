//
//  SuggestionsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Namespace private var namespace
    
    @Query var recipes: [RecipeModal]
    
    @Query var food: [FoodModal]
    
    var filteredRecipes: [RecipeModal] {
        recipes.filter { recipe in
            guard let recipeIngredients = recipe.ingredients else { return false }
            
            return recipeIngredients.allSatisfy { recipeFood in
                guard let requiredIngredient = recipeFood.ingredient else { return false }
                guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                
                return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredRecipes.count > 0 {
                    Section {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink {
                                RecipeDetailsView(recipe: recipe)
                                    .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
                            } label: {
                                SuggestionRowView(recipe: recipe)
                                    .matchedTransitionSource(id: recipe.id, in: namespace)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                } else {
                    ContentUnavailableView("No suggestions found", systemImage: "exclamationmark", description: Text("You can add ingredients by tapping on the Refill button in the Food section"))
                }
            }
            .listStyle(.plain)
            .navigationTitle(filteredRecipes.count > 0 ? "Suggestions for you" : "No suggestions for now")
        }
    }
}

#Preview {
    SuggestionsView()
}
