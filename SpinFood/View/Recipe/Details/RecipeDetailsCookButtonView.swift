//
//  RecipeDetailsCookButtonView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

struct RecipeDetailsCookButtonView: View {
    var recipe: RecipeModel
    var hasAllIngredients: Bool
    
    @Binding var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            VStack(spacing: 6) {
                Button {
                    if hasAllIngredients {
                        if let steps = recipe.steps, !steps.isEmpty {
                            return activeRecipeDetailSheet = .cookNow(steps)
                        } else if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            return activeRecipeDetailSheet = .confirmEat
                        }
                    }
                } label: {
                    Text("Cook")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!hasAllIngredients)

                if !hasAllIngredients {
                    let missingCount = recipe.missingIngredients.count
                    Text("\(missingCount) ingredient\(missingCount == 1 ? "" : "s") missing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

#Preview {
    RecipeDetailsCookButtonView(
        recipe: RecipeModel(name: "Carbonara"),
        hasAllIngredients: false,
        activeRecipeDetailSheet: .constant(nil)
    )
}
