//
//  SummaryView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Namespace private var namespace
    
    @State private var showStoreView: Bool = false
    @State private var showPaywall: Bool = false
    
    @Query var recipes: [RecipeModel]
    
    @Query var foods: [FoodModel]
    
    @Query var consumptions: [FoodConsumptionModel]
    
    @Query var refills: [FoodRefillModel]
    
    var filteredRecipes: [RecipeModel] {
        recipes.filter { recipe in
            guard let recipeIngredients = recipe.ingredients else { return false }
            
            return recipeIngredients.allSatisfy { recipeFood in
                guard let requiredIngredient = recipeFood.ingredient else { return false }
                guard let inventoryItem = foods.first(where: { $0.id == requiredIngredient.id }) else { return false }
                
                // If units are the same, direct comparison
                if requiredIngredient.unit == inventoryItem.unit {
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
                
                // Convert both quantities to grams for comparison when units differ
                let inventoryQuantityInGrams = inventoryItem.unit.convertToGrams(inventoryItem.currentQuantity)
                let neededQuantityInGrams = requiredIngredient.unit.convertToGrams(recipeFood.quantityNeeded)
                
                return inventoryQuantityInGrams >= neededQuantityInGrams
            }
        }
    }
    
    var cookedRecipes: [RecipeModel] {
        recipes.filter { $0.cookedAt.count > 0 }
    }
    
    var totalRecipeCooked: Int {
        var totalCooked: Int = 0
        
        for recipe in cookedRecipes {
            totalCooked += recipe.cookedAt.count
        }
        
        return totalCooked
    }
    
    var totalFoodEaten: Int {
        consumptions.count
    }
    
    var totalFoodRefilled: Int {
        refills.count
    }
        
    var body: some View {
        VStack {
            if filteredRecipes.count == 0 && totalRecipeCooked == 0 && totalFoodEaten == 0 && totalFoodRefilled == 0 {
                ContentUnavailableView("No data to show", systemImage: "chart.pie", description: Text("Start cooking recipes or adding food to see your statistics and suggestions"))
            } else {
                List {                    
                    TotalRecipeCookedWidgetView(totalRecipeCooked: totalRecipeCooked, cookedRecipes: cookedRecipes)
                    
                    TotalFoodEatenWidgetView(totalFoodEaten: totalFoodEaten)
                    
                    TotalFoodRefilledWidgetView(totalFoodRefilled: totalFoodRefilled)
                }
            }
        }
        .navigationTitle("Summary")
    }
}

#Preview {
    SummaryView()
}
