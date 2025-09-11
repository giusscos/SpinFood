//
//  RecipeDetailsIngredientView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

struct RecipeDetailsIngredientView: View {
    var recipe: RecipeModel
    var missingIngredients: [RecipeFoodModel]
    
    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            VStack (alignment: .leading) {
                Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                    .font(.headline)
                
                VStack {
                    ForEach(ingredients) { value in
                        if let ingredient = value.ingredient {
                            let missingIngredient = missingIngredients.contains(where: { $0.id == value.id })
                            HStack (alignment: .lastTextBaseline) {
                                Text(ingredient.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(value.quantityNeeded, format: .number)
                                    .font(.headline)
                                    .foregroundStyle(missingIngredient ? .red : .primary)
                                +
                                Text(ingredient.unit.abbreviation)
                                    .font(.headline)
                                    .foregroundStyle(missingIngredient ? .red : .secondary)
                            }
                            .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical)
            }
            .padding()
        }
    }
}

#Preview {
    RecipeDetailsIngredientView(recipe: RecipeModel(name: "Carbonara"), missingIngredients: [])
}
