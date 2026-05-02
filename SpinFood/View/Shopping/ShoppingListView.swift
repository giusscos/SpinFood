import SwiftUI
import SwiftData

struct ShoppingItem: Identifiable, Hashable {
    var id: UUID
    var foodName: String
    var category: FoodCategory
    var neededQuantity: Decimal
    var unit: FoodUnit
    var recipes: [String]

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ShoppingItem, rhs: ShoppingItem) -> Bool { lhs.id == rhs.id }
}

struct ShoppingListView: View {
    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]

    @State private var checkedItems: Set<UUID> = []
    @State private var selectedRecipes: Set<UUID> = []
    @State private var showRecipePicker: Bool = false

    var recipesToConsider: [RecipeModel] {
        selectedRecipes.isEmpty
            ? recipes
            : recipes.filter { selectedRecipes.contains($0.id) }
    }

    var shoppingItems: [ShoppingItem] {
        var aggregated: [UUID: ShoppingItem] = [:]

        for recipe in recipesToConsider {
            guard let ingredients = recipe.ingredients else { continue }
            for recipeFood in ingredients {
                guard let food = recipeFood.ingredient else { continue }
                let needed = recipeFood.quantityNeeded - food.currentQuantity
                guard needed > 0 else { continue }

                if var existing = aggregated[food.id] {
                    existing.neededQuantity += needed
                    existing.recipes.append(recipe.name)
                    aggregated[food.id] = existing
                } else {
                    aggregated[food.id] = ShoppingItem(
                        id: food.id,
                        foodName: food.name,
                        category: food.category,
                        neededQuantity: needed,
                        unit: food.unit,
                        recipes: [recipe.name]
                    )
                }
            }
        }

        return aggregated.values.sorted { $0.category.rawValue < $1.category.rawValue }
    }

    var groupedItems: [(FoodCategory, [ShoppingItem])] {
        let groups = Dictionary(grouping: shoppingItems, by: \.category)
        return groups.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var uncheckedCount: Int { shoppingItems.filter { !checkedItems.contains($0.id) }.count }

    var body: some View {
        NavigationStack {
            Group {
                if shoppingItems.isEmpty {
                    emptyState
                } else {
                    shoppingList
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRecipePicker = true
                    } label: {
                        Label("Filter recipes", systemImage: "slider.horizontal.3")
                    }
                }

                if !checkedItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear checked") {
                            checkedItems.removeAll()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipePickerSheet(recipes: recipes, selectedRecipes: $selectedRecipes)
            }
        }
    }

    private var shoppingList: some View {
        List {
            if !checkedItems.isEmpty || !selectedRecipes.isEmpty {
                Section {
                    HStack {
                        if !selectedRecipes.isEmpty {
                            Label(
                                "\(selectedRecipes.count) recipe\(selectedRecipes.count == 1 ? "" : "s") selected",
                                systemImage: "fork.knife"
                            )
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                        }
                        Spacer()
                        Text("\(uncheckedCount) item\(uncheckedCount == 1 ? "" : "s") left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(groupedItems, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        ShoppingItemRow(
                            item: item,
                            isChecked: checkedItems.contains(item.id),
                            onToggle: { toggleCheck(item) }
                        )
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "cart.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
            }

            Text("Nothing to buy!")
                .font(.title2)
                .fontWeight(.bold)

            Text(recipes.isEmpty
                    ? "Add recipes and link ingredients to generate your shopping list."
                    : "All your recipe ingredients are stocked up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggleCheck(_ item: ShoppingItem) {
        if checkedItems.contains(item.id) {
            checkedItems.remove(item.id)
        } else {
            checkedItems.insert(item.id)
        }
    }
}

// MARK: - Row

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let isChecked: Bool
    let onToggle: () -> Void

    private var categoryColor: Color {
        switch item.category {
        case .produce:   return .green
        case .dairy:     return .yellow
        case .meat:      return .red
        case .seafood:   return .blue
        case .grains:    return .orange
        case .pantry:    return .brown
        case .frozen:    return .cyan
        case .beverages: return .indigo
        case .snacks:    return .purple
        case .other:     return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.foodName)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)

                Text(item.recipes.prefix(2).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(item.neededQuantity.formatted()) \(item.unit.abbreviation)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isChecked ? Color.secondary : categoryColor)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Recipe Picker Sheet

struct RecipePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let recipes: [RecipeModel]
    @Binding var selectedRecipes: Set<UUID>

    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
                    Button {
                        if selectedRecipes.contains(recipe.id) {
                            selectedRecipes.remove(recipe.id)
                        } else {
                            selectedRecipes.insert(recipe.id)
                        }
                    } label: {
                        HStack {
                            Text(recipe.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedRecipes.contains(recipe.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter by Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { selectedRecipes.removeAll() }
                        .disabled(selectedRecipes.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
