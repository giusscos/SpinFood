//
//  RecipeDetailsIngredientView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

private struct IngredientCardView: View {
    var value: RecipeFoodModel
    var isMissing: Bool

    var body: some View {
        if let ingredient = value.ingredient {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isMissing ? .red.opacity(0.15) : categoryColor(ingredient.category).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: ingredient.category.icon)
                        .font(.body)
                        .foregroundStyle(isMissing ? .red : categoryColor(ingredient.category))
                }

                Text(ingredient.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isMissing ? .red : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("\(value.quantityNeeded.formatted()) \(ingredient.unit.abbreviation)")
                    .font(.caption2)
                    .foregroundStyle(isMissing ? .red.opacity(0.8) : .secondary)
            }
            .frame(width: 88, height: 110)
            .padding(8)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMissing ? .red.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
    }

    func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
            case .produce: return .green
            case .dairy: return .yellow
            case .meat: return .red
            case .seafood: return .blue
            case .grains: return .orange
            case .pantry: return .brown
            case .frozen: return .cyan
            case .beverages: return .indigo
            case .snacks: return .purple
            case .other: return .gray
        }
    }
}

struct RecipeDetailsIngredientView: View {
    var recipe: RecipeModel
    var missingIngredients: [RecipeFoodModel]

    private let rows = Array(repeating: GridItem(.fixed(140), spacing: 10), count: 3)

    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Ingredients")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Text("\(ingredients.count) item\(ingredients.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(.capsule)
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: Array(repeating: GridItem(.fixed(140), spacing: 10), count: min(3, ingredients.count)), spacing: 10) {
                        ForEach(ingredients) { value in
                            let isMissing = missingIngredients.contains(where: { $0.id == value.id })
                            IngredientCardView(value: value, isMissing: isMissing)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    RecipeDetailsIngredientView(recipe: RecipeModel(name: "Carbonara"), missingIngredients: [])
}
