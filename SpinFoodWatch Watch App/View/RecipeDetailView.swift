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
        guard let ingredients = recipe.ingredients else { return [] }
        
        return ingredients.filter { ingredient in
            guard let requiredIngredient = ingredient.ingredient else { return false }
            guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return true }
            
            return inventoryItem.currentQuantity < ingredient.quantityNeeded
        }
    }
    
    var hasAllIngredients: Bool {
        return missingIngredients.isEmpty
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
                
                // Cook Button
                Button {
                    // Start cooking
                    if hasAllIngredients {
                        // Record cooking timestamp
                        recipe.cookedAt.append(Date())
                        
                        // Navigate to step by step view
                    }
                } label: {
                    Label("Start Cooking", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasAllIngredients)
                
                if !hasAllIngredients {
                    Text("Missing ingredients")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                NavigationLink(destination: RecipeStepByStepView(recipe: recipe)) {
                    Label("View Steps", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
        .navigationTitle(recipe.name)
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