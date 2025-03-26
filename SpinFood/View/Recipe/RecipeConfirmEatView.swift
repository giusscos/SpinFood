//
//  RecipeConfirmEatView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import Foundation
import SwiftUI
import SwiftData

struct RecipeConfirmEatView: View {
    @Environment(\.dismiss) var dismiss
    
    @Query var food: [FoodModel]
    
    var ingredients: [RecipeFoodModel]
    var recipe: RecipeModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center) {
                        Text("Are you sure?")
                            .font(.headline)
                        
                        Text("This are the ingredients you will consume:")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                
                Section {
                    ForEach(ingredients) { value in
                        if let food = value.ingredient {
                            HStack {
                                Text(food.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 2) {
                                    Text("\(value.quantityNeeded)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(food.unit.abbreviation)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Ingredients")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") {
                        confirmRecipe()
                    }
                }
            }
        }
    }
    
    func confirmRecipe() {
        let now = Date.now
        
        for ingredient in ingredients {
            if let food = ingredient.ingredient {
                food.currentQuantity -= ingredient.quantityNeeded
                
                // Create a consumption record with the exact quantity
                let consumption = FoodConsumptionModel(
                    consumedAt: now,
                    quantity: ingredient.quantityNeeded,
                    unit: food.unit,
                    food: food
                )
                
                if food.consumptions == nil {
                    food.consumptions = [consumption]
                } else {
                    food.consumptions?.append(consumption)
                }
                
                // Also keep the old method for backward compatibility
                let quantity = Int(NSDecimalNumber(decimal: ingredient.quantityNeeded).intValue)
                for _ in 0..<quantity {
                    food.eatenAt.append(now)
                }
            }
        }
        
        recipe.cookedAt.append(now)
        
        dismiss()
    }
}

#Preview {
    RecipeConfirmEatView(ingredients: [], recipe: RecipeModel(name: "Carbonara"))
}
