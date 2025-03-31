//
//  RecipeUtils.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import Foundation
import SwiftData

/// Utility class for recipe-related operations
class RecipeUtils {
    
    /// Consumes all the ingredients needed for a recipe if they are available
    /// - Parameters:
    ///   - recipe: The recipe whose ingredients will be consumed
    ///   - modelContext: The SwiftData model context to save changes
    ///   - foodInventory: The food inventory to check and update
    /// - Returns: True if all ingredients were successfully consumed, false otherwise
    @discardableResult
    static func consumeRecipeIngredients(recipe: RecipeModel, modelContext: ModelContext, foodInventory: [FoodModel]) -> Bool {
        // Check if all ingredients are available
        guard hasAllIngredientsAvailable(recipe: recipe, foodInventory: foodInventory) else {
            return false
        }
        
        // Update ingredient inventory by decreasing quantities
        if let ingredients = recipe.ingredients {
            for ingredient in ingredients {
                if let foodItem = ingredient.ingredient {
                    // Find the corresponding food item in the inventory
                    if let inventoryItem = foodInventory.first(where: { $0.id == foodItem.id }) {
                        let consumptionQuantity = ingredient.quantityNeeded
                        
                        // Create a consumption record
                        let consumption = FoodConsumptionModel(
                            consumedAt: Date(),
                            quantity: consumptionQuantity,
                            unit: inventoryItem.unit,
                            food: inventoryItem
                        )
                        
                        // Update current quantity
                        inventoryItem.currentQuantity = max(0, inventoryItem.currentQuantity - consumptionQuantity)
                        
                        // Add consumption to model context
                        modelContext.insert(consumption)
                    }
                }
            }
        }
        
        return true
    }
    
    /// Checks if all ingredients for a recipe are available in the inventory
    /// - Parameters:
    ///   - recipe: The recipe to check
    ///   - foodInventory: The food inventory to check against
    /// - Returns: True if all ingredients are available, false otherwise
    static func hasAllIngredientsAvailable(recipe: RecipeModel, foodInventory: [FoodModel]) -> Bool {
        guard let ingredients = recipe.ingredients else { return true }
        
        for ingredient in ingredients {
            guard let requiredIngredient = ingredient.ingredient else { continue }
            guard let inventoryItem = foodInventory.first(where: { $0.id == requiredIngredient.id }) else {
                return false
            }
            
            if inventoryItem.currentQuantity < ingredient.quantityNeeded {
                return false
            }
        }
        
        return true
    }
    
    /// Finds missing ingredients for a recipe in the inventory
    /// - Parameters:
    ///   - recipe: The recipe to check
    ///   - foodInventory: The food inventory to check against
    /// - Returns: Array of ingredients that are missing or insufficient
    static func findMissingIngredients(recipe: RecipeModel, foodInventory: [FoodModel]) -> [RecipeFoodModel] {
        guard let ingredients = recipe.ingredients else { return [] }
        
        return ingredients.filter { ingredient in
            guard let requiredIngredient = ingredient.ingredient else { return false }
            guard let inventoryItem = foodInventory.first(where: { $0.id == requiredIngredient.id }) else { return true }
            
            return inventoryItem.currentQuantity < ingredient.quantityNeeded
        }
    }
} 
