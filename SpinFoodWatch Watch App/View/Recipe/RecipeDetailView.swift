//
//  RecipeDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var food: [FoodModel]
    
    var recipe: RecipeModel
    
    var missingIngredients: [RecipeFoodModel] {
        return RecipeUtils.findMissingIngredients(recipe: recipe, foodInventory: food)
    }
    
    var hasAllIngredients: Bool {
        return RecipeUtils.hasAllIngredientsAvailable(recipe: recipe, foodInventory: food)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Recipe Image
                if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Recipe Description
                if !recipe.descriptionRecipe.isEmpty {
                    Text(recipe.descriptionRecipe)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                // Ingredients Section
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            if let food = ingredient.ingredient {
                                HStack {
                                    Text(food.name)
                                        .font(.footnote)
                                    Spacer()
                                    Text("\(ingredient.quantityNeeded) \(food.unit.abbreviation)")
                                        .font(.footnote)
                                        .foregroundStyle(missingIngredients.contains(where: { $0.id == ingredient.id }) ? .red : .secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Ingredients")
                            .font(.headline)
                    }
                }
                
                if let steps = recipe.steps, !steps.isEmpty {
                    Section {
                        ForEach(steps) { step in
                            VStack(alignment: .leading) {
                                Text(step.text)
                                    .font(.footnote)
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("Steps")
                            .font(.headline)
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                // Cook Button
                NavigationLink {
                    RecipeStepByStepView(recipe: recipe)
                } label: {
                    Label("Start Cooking", systemImage: "play.fill")
                }
                .tint(hasAllIngredients ? .purple : .secondary)
                .disabled(!hasAllIngredients)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    let sampleRecipe = RecipeModel(name: "Pasta Carbonara", 
                                   descriptionRecipe: "Classic Italian dish with eggs, cheese and bacon")
    
    return RecipeDetailView(recipe: sampleRecipe)
        .modelContainer(container)
} 
