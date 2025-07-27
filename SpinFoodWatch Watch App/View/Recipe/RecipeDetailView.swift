//
//  RecipeDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    enum ActiveRecipeDetailSheet: Identifiable {
        case confirmEat
        case cookNow
        
        var id: String {
            switch self {
                case .confirmEat:
                    return "confirmEat"
                case .cookNow:
                    return "cookNow"
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    
    @Query var food: [FoodModel]
    
    @State private var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    var recipe: RecipeModel
    
    var missingIngredients: [RecipeFoodModel] {
        return RecipeUtils.findMissingIngredients(recipe: recipe, foodInventory: food)
    }
    
    var hasAllIngredients: Bool {
        return RecipeUtils.hasAllIngredientsAvailable(recipe: recipe, foodInventory: food)
    }
    
    var body: some View {
            List {
                Section {
                    if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .listRowBackground(Color.clear)
                
                if !recipe.descriptionRecipe.isEmpty {
                    Section {
                        Text(recipe.descriptionRecipe)
                    }
                }
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            if let food = ingredient.ingredient {
                                HStack {
                                    Text(food.name)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    Text("\(ingredient.quantityNeeded)")
                                        .font(.headline)
                                        .foregroundStyle(missingIngredients.contains(where: { $0.id == ingredient.id }) ? .red : .secondary)
                                    +
                                    Text("\(food.unit.abbreviation)")
                                        .font(.subheadline)
                                        .foregroundStyle(missingIngredients.contains(where: { $0.id == ingredient.id }) ? .red : .secondary)
                                }
                            }
                        }
                    } header: {
                        Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                    }
                }
                
                if let steps = recipe.steps, !steps.isEmpty {
                    Section {
                        ForEach(steps) { step in
                            VStack(alignment: .leading, spacing: 8) {
                                if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: 127)
                                        .clipShape(.rect(cornerRadius: 20))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Text(step.text)
                                    .padding(4)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    } header: {
                        Text(steps.count == 1 ? "Step" : "Steps")
                    }
                }
                
                Button {
                    if hasAllIngredients, let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        return activeRecipeDetailSheet = .confirmEat
                    }
                } label: {
                    Label("Start Cooking", systemImage: "frying.pan.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!hasAllIngredients)
                .listRowBackground(Color.clear)
            }
            .navigationTitle(recipe.name)
            .sheet(item: $activeRecipeDetailSheet) { sheet in
                switch sheet {
                    case .confirmEat:
                        RecipeConfirmEatView(recipe: recipe)
                    case .cookNow:
                        RecipeConfirmEatView(recipe: recipe)
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
