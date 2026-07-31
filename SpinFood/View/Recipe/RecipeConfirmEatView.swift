import SwiftUI
import SwiftData

struct RecipeConfirmEatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query var foods: [FoodModel]

    var recipe: RecipeModel
    var initialServings: Int? = nil
    /// When `false`, servings were already chosen at cook start and the stepper is hidden.
    var allowsServingsAdjustment: Bool = true
    var onConfirmed: (() -> Void)? = nil

    @State private var selectedServings: Int = 1

    private var scale: Decimal {
        guard recipe.servings > 0 else { return 1 }
        return Decimal(selectedServings) / Decimal(recipe.servings)
    }

    private var maxServings: Int {
        // Touch the query so pantry edits refresh this computed limit.
        let _ = foods.count
        let pantryMax = recipe.maxCookableServings
        if pantryMax <= 0 { return 1 }
        return min(20, pantryMax)
    }

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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cooking \(recipe.name) will deduct the ingredients from your pantry.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        if allowsServingsAdjustment {
                            HStack {
                                Label(
                                    "\(selectedServings) \(selectedServings == 1 ? String(localized: "serving") : String(localized: "servings"))",
                                    systemImage: "person.2"
                                )
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(selectedServings == recipe.servings ? .secondary : .primary)

                                Spacer()

                                Stepper("", value: $selectedServings, in: 1...maxServings)
                                    .labelsHidden()
                            }

                            if selectedServings != recipe.servings {
                                Text("Quantities scaled from \(recipe.servings) servings")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.orange)
                            }

                            Text("Up to \(maxServings) based on your pantry")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        } else {
                            Label(
                                "\(selectedServings) \(selectedServings == 1 ? String(localized: "serving") : String(localized: "servings"))",
                                systemImage: "person.2"
                            )
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        ForEach(ingredients) { ingredient in
                            IngredientRowView(ingredient: ingredient, scale: scale, recipeServings: recipe.servings)
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
            .onAppear {
                let fallback = max(1, recipe.servings)
                let desired = initialServings ?? fallback
                selectedServings = min(maxServings, max(1, desired))
            }
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
                        onConfirmed?()
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
        guard let ingredients = recipe.ingredients, !ingredients.isEmpty else {
            recipe.finishCookingSession()
            return
        }
        recipe.cookedAt.append(Date.now)
        recipe.finishCookingSession()
        for ingredient in ingredients {
            updateIngredientQuantity(ingredient)
        }
    }

    private func updateIngredientQuantity(_ ingredient: RecipeFoodModel) {
        guard let inventoryItem = ingredient.ingredient else { return }

        let consumed = ingredient.quantityNeeded * scale
        inventoryItem.currentQuantity -= consumed
        if inventoryItem.currentQuantity < 0 {
            inventoryItem.currentQuantity = 0
        }

        let consumption = FoodConsumptionModel(
            consumedAt: Date.now,
            quantity: consumed,
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

struct IngredientRowView: View {
    let ingredient: RecipeFoodModel
    var scale: Decimal = 1
    var recipeServings: Int = 1

    var body: some View {
        if let item = ingredient.ingredient {
            let perServing = ingredient.quantityNeeded / Decimal(max(1, recipeServings))
            let insufficient = item.currentQuantity < perServing
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(ingredient.quantityNeeded * scale, format: .number)
                        .font(.system(.headline, design: .rounded))
                    +
                    Text(" \(item.unit.abbreviation)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: item.category.icon)
                    HStack(spacing: 0) {
                        Text(item.currentQuantity, format: .number)
                        Text(item.unit.abbreviation)
                    }
                    Text("in pantry")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(insufficient ? .orange : .secondary)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    RecipeConfirmEatView(recipe: RecipeModel(name: "Carbonara"))
}
