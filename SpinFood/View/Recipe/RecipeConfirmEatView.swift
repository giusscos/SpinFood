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
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .padding(12)
                            .background(.white)
                            .clipShape(.rect(cornerRadius: 2))
                            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                            .overlay(alignment: .top) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.white.opacity(0.6))
                                    .frame(width: 56, height: 16)
                                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                                    .offset(y: -8)
                            }
                            .rotationEffect(.degrees(-1))
                            .padding(.vertical, 16)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ready to eat?")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(.body, design: .rounded))
                    }
                }

            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        consumeFood()
                        dismiss()
                    } label: {
                        Label("Confirm", systemImage: "fork.knife")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .labelStyle(.titleOnly)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
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
