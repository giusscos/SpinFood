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
    
    var ingredients: [RecipeFoodModel]
    var recipe: RecipeModel
    var isFromCookingFlow: Bool
    
    init(ingredients: [RecipeFoodModel], recipe: RecipeModel, isFromCookingFlow: Bool = false) {
        self.ingredients = ingredients
        self.recipe = recipe
        self.isFromCookingFlow = isFromCookingFlow
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    let title = "You have all the ingredients. Do you want to cook \(recipe.name)?"
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                if !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            IngredientRowView(ingredient: ingredient)
                        }
                    } header: {
                        Text("Ingredients")
                    }
                }
            }
            .navigationTitle(isFromCookingFlow ? "Complete Recipe" : "Cook Recipe")
            .navigationBarTitleDisplayMode(.inline)
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
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    private func consumeFood() {
        // Mark the recipe as cooked
        recipe.cookedAt.append(Date.now)
        
        // Reset the step index after completing
        recipe.lastStepIndex = 0
        
        // Find and update ingredient stocks
        for ingredient in ingredients {
            updateIngredientQuantity(ingredient)
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

// Extract the ingredient row to a separate view
struct IngredientRowView: View {
    let ingredient: RecipeFoodModel
    
    var body: some View {
        if let item = ingredient.ingredient {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    
                    Text(item.unit.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                let quantityText = "\(ingredient.quantityNeeded) \(item.unit.abbreviation)"
                Text("- \(quantityText)")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    RecipeConfirmEatView(ingredients: [], recipe: RecipeModel(name: "Carbonara"))
}
