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

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }
        
    var body: some View {
        NavigationStack {
            List {
                if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                    Section {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 200)
                            .clipShape(.rect(cornerRadius: 2))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                            .rotationEffect(.degrees(-1))
                            .padding(.vertical, 8)
                    }
                    .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cooking \(recipe.name) will deduct the ingredients from your pantry.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        Label("\(recipe.servings) \(recipe.servings == 1 ? "serving" : "servings")", systemImage: "person.2")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            IngredientRowView(ingredient: ingredient)
                                .listRowBackground(paperBackground)
                        }
                    } header: {
                        Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .textCase(nil)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(paperBackground.ignoresSafeArea())
            .navigationTitle("Ready to eat?")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(.body, design: .rounded))
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        consumeFood()
                        dismiss()
                    } label: {
                        Text("Confirm")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                }
            }
        }
    }
    
    private func consumeFood() {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            recipe.cookedAt.append(Date.now)
            recipe.lastStepIndex = 0
            
            for ingredient in ingredients {
                updateIngredientQuantity(ingredient)
            }
        }
    }
    
    private func updateIngredientQuantity(_ ingredient: RecipeFoodModel) {
        guard let requiredIngredient = ingredient.ingredient else { return }
        
        if let inventoryItem = foods.first(where: { $0.id == requiredIngredient.id }) {
            inventoryItem.currentQuantity -= ingredient.quantityNeeded
            
            if inventoryItem.currentQuantity < 0 {
                inventoryItem.currentQuantity = 0
            }
            
            let consumption = FoodConsumptionModel(
                consumedAt: Date.now,
                quantity: ingredient.quantityNeeded,
                unit: inventoryItem.unit,
                food: inventoryItem
            )
            
            if inventoryItem.consumptions == nil {
                inventoryItem.consumptions = [consumption]
            } else {
                inventoryItem.consumptions?.append(consumption)
            }
        }
    }
}

struct IngredientRowView: View {
    let ingredient: RecipeFoodModel

    var body: some View {
        if let item = ingredient.ingredient {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(ingredient.quantityNeeded, format: .number)
                        .font(.system(.headline, design: .rounded))
                    +
                    Text(" \(item.unit.abbreviation)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: item.category.icon)
                    Text(item.currentQuantity, format: .number)
                    Text(item.unit.abbreviation)
                    Text("in pantry")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    RecipeConfirmEatView(recipe: RecipeModel(name: "Carbonara"))
}
