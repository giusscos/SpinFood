//
//  RecipeConfirmEatView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

struct RecipeConfirmEatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModel]
    
    var recipe: RecipeModel
        
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("You have all the ingredients. Do you want to cook \(recipe.name)?")
                        .foregroundStyle(.secondary)
                }
                .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            IngredientRowView(ingredient: ingredient)
                        }
                    } header: {
                        Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                    }
                }
            }
            .navigationTitle("Ready to eat?")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        consumeFood()
                        
                        dismiss()
                    } label: {
                        Text("Confirm")
                    }
                }
            }
        }
    }
    
    private func consumeFood() {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            // Mark the recipe as cooked
            recipe.cookedAt.append(Date.now)
            
            // Reset the step index after completing
            recipe.lastStepIndex = 0
            
            // Find and update ingredient stocks
            for ingredient in ingredients {
                updateIngredientQuantity(ingredient)
            }
        }
    }
    
    private func updateIngredientQuantity(_ ingredient: RecipeFoodModel) {
        guard let requiredIngredient = ingredient.ingredient else { return }
        
        // Find the food item in the database
        if let inventoryItem = foods.first(where: { $0.id == requiredIngredient.id }) {
            // Reduce the quantity in inventory
            inventoryItem.currentQuantity -= ingredient.quantityNeeded
            
            // Ensure we don't go below zero
            if inventoryItem.currentQuantity < 0 {
                inventoryItem.currentQuantity = 0
            }
            
            // Create a consumption record
            let consumption = FoodConsumptionModel(
                consumedAt: Date.now,
                quantity: ingredient.quantityNeeded,
                unit: inventoryItem.unit,
                food: inventoryItem
            )
            
            // Add it to the food's consumption history
            if inventoryItem.consumptions == nil {
                inventoryItem.consumptions = [consumption]
            } else {
                inventoryItem.consumptions?.append(consumption)
            }
            
            // Also keep track in the legacy property for backward compatibility
            inventoryItem.eatenAt.append(Date.now)
        }
    }
}

struct IngredientRowView: View {
    let ingredient: RecipeFoodModel
    
    var body: some View {
        if let item = ingredient.ingredient {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("- \("\(ingredient.quantityNeeded) \(item.unit.abbreviation)")")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    RecipeConfirmEatView(recipe: RecipeModel(name: "Carbonara"))
}
