//
//  EditRecipeIngredientView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/07/25.
//

import SwiftUI

struct EditRecipeIngredientView: View {
    var foods: [FoodModel]

    @Binding var ingredients: [RecipeFoodModel]
    @Binding var selectedFood: FoodModel?
    @Binding var quantityNeeded: Decimal?

    var body: some View {
        if !foods.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Text("Ingredients")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    if !ingredients.isEmpty {
                        Text("\(ingredients.count) item\(ingredients.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.secondary.opacity(0.12))
                            .clipShape(.capsule)
                    }
                }

                // Ingredient list
                if !ingredients.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, recipeIngredient in
                            if let ingredient = recipeIngredient.ingredient {
                                VStack(spacing: 0) {
                                    HStack(alignment: .center, spacing: 12) {
                                        Text(ingredient.emoji.isEmpty ? ingredient.category.defaultEmoji : ingredient.emoji)
                                            .font(.system(size: 20))
                                            .frame(width: 28)

                                        Text(ingredient.name)
                                            .font(.body)
                                            .lineLimit(1)

                                        Spacer()

                                        Text(recipeIngredient.quantityNeeded, format: .number)
                                            .font(.body.weight(.semibold))
                                        +
                                        Text(" \(ingredient.unit.abbreviation)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        Button(role: .destructive) {
                                            withAnimation {
                                                ingredients.removeAll { $0.id == recipeIngredient.id }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .imageScale(.medium)
                                        }
                                        .foregroundStyle(.white, .red)
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.vertical, 10)

                                    if index < ingredients.count - 1 {
                                        Divider()
                                            .padding(.leading, 36)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }

                // Add ingredient row
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add ingredient")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Picker("Select Ingredient", selection: $selectedFood) {
                            ForEach(foods) { value in
                                Text("\(value.emoji.isEmpty ? value.category.defaultEmoji : value.emoji) \(value.name)")
                                    .tag(value as FoodModel?)
                            }
                        }
                        .tint(.primary)
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: .rect(cornerRadius: 10))

                        if let selectedFood {
                            HStack(spacing: 4) {
                                TextField("Qty", value: $quantityNeeded, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 56)
                                    .multilineTextAlignment(.trailing)

                                Text(selectedFood.unit.abbreviation)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: .rect(cornerRadius: 10))
                        }
                    }

                    Button {
                        guard let food = selectedFood, let qty = quantityNeeded, qty > 0 else { return }
                        let newIngredient = RecipeFoodModel(ingredient: food, quantityNeeded: qty)
                        withAnimation {
                            ingredients.append(newIngredient)
                        }
                        selectedFood = foods.first
                        quantityNeeded = nil
                    } label: {
                        Text("Add")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.accent)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(quantityNeeded == nil || quantityNeeded == 0)
                }
            }
            .padding()
        }
    }
}

#Preview {
    EditRecipeIngredientView(
        foods: [FoodModel(name: "Carrots")],
        ingredients: .constant([RecipeFoodModel(ingredient: FoodModel(name: "Carrots"), quantityNeeded: 0.0)]),
        selectedFood: .constant(nil),
        quantityNeeded: .constant(0.0)
    )
}
