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
            }
            .listStyle(.plain)
            .navigationTitle("Suggestions for you")
        }
    }
}

#Preview {
    SuggestionsView()
}
