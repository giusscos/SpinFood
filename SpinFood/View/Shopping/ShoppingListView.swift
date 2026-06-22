import SwiftUI
import SwiftData

// MARK: - Models

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

enum ShoppingSortOption: CaseIterable {
    case name, quantityNeeded

    var label: String {
        switch self {
        case .name:           return "Name A–Z"
        case .quantityNeeded: return "Quantity Needed"
        }
    }
}

// MARK: - View

struct ShoppingListView: View {
    @Environment(Store.self) var store

    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]

    @State private var checkedItems: Set<UUID> = []
    @State private var selectedRecipes: Set<UUID> = []
    @State private var showRecipePicker: Bool = false
    @State private var showPaywall: Bool = false
    @State private var sortOption: ShoppingSortOption = .name
    @State private var filterCategory: FoodCategory? = nil
    @State private var foodsToRefill: [FoodModel] = []
    @State private var showRefillSheet: Bool = false

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

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

        return aggregated.values.sorted { $0.foodName < $1.foodName }
    }

    var displayedItems: [ShoppingItem] {
        var items = shoppingItems

        if let cat = filterCategory {
            items = items.filter { $0.category == cat }
        }

        switch sortOption {
        case .name:
            items.sort { $0.foodName < $1.foodName }
        case .quantityNeeded:
            items.sort { $0.neededQuantity > $1.neededQuantity }
        }

        return items
    }

    var groupedDisplayedItems: [(FoodCategory, [ShoppingItem])] {
        let groups = Dictionary(grouping: displayedItems, by: \.category)
        return groups.sorted { $0.key.rawValue < $1.key.rawValue }
    }

    var uncheckedCount: Int { displayedItems.filter { !checkedItems.contains($0.id) }.count }

    var checkedFoodsForRefill: [FoodModel] {
        foods.filter { checkedItems.contains($0.id) }
    }

    var allFoodsNeedingRefill: [FoodModel] {
        foods.filter { $0.currentQuantity < $0.quantity }
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayedItems.isEmpty {
                    emptyState
                } else {
                    shoppingList
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .navigationTitle("Shopping List")
            .toolbar {
                if !checkedItems.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear") {
                            checkedItems.removeAll()
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Menu {
                            Picker("Sort by", selection: $sortOption) {
                                ForEach(ShoppingSortOption.allCases, id: \.self) { opt in
                                    Text(opt.label).tag(opt)
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }

                        Menu {
                            Picker("Category", selection: $filterCategory) {
                                Text("All Categories").tag(Optional<FoodCategory>.none)
                                Divider()
                                ForEach(FoodCategory.allCases, id: \.self) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon)
                                        .tag(Optional(cat))
                                }
                            }
                        } label: {
                            Label(
                                filterCategory.map { $0.rawValue } ?? "Category",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                        }

                        Button {
                            if store.hasActiveSubscription {
                                showRecipePicker = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Label(
                                selectedRecipes.isEmpty ? "Filter by Recipe" : "\(selectedRecipes.count) Recipe\(selectedRecipes.count == 1 ? "" : "s") Selected",
                                systemImage: store.hasActiveSubscription ? "fork.knife" : "lock.fill"
                            )
                        }

                        Divider()

                        Button {
                            foodsToRefill = allFoodsNeedingRefill
                            showRefillSheet = true
                        } label: {
                            Label("Refill All Food", systemImage: "bag.fill.badge.plus")
                        }
                        .disabled(allFoodsNeedingRefill.isEmpty)
                    } label: {
                        Label("Menu", systemImage: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !checkedItems.isEmpty {
                    Button {
                        foodsToRefill = checkedFoodsForRefill
                        showRefillSheet = true
                    } label: {
                        Label(
                            "Refill \(checkedItems.count) Selected",
                            systemImage: "bag.fill.badge.plus"
                        )
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding()
                    .background(.bar)
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipePickerSheet(recipes: recipes, selectedRecipes: $selectedRecipes)
            }
            .sheet(isPresented: $showRefillSheet, onDismiss: {
                foodsToRefill = []
            }) {
                NavigationStack {
                    FoodRefillView(food: foodsToRefill)
                        .presentationDragIndicator(.visible)
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Shopping list

    private var shoppingList: some View {
        List {
            if !checkedItems.isEmpty || !selectedRecipes.isEmpty || filterCategory != nil {
                Section {
                    HStack {
                        if !selectedRecipes.isEmpty {
                            Label(
                                "\(selectedRecipes.count) recipe\(selectedRecipes.count == 1 ? "" : "s") selected",
                                systemImage: "fork.knife"
                            )
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                        }
                        if let cat = filterCategory {
                            Label(cat.rawValue, systemImage: cat.icon)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(categoryColor(for: cat))
                        }
                        Spacer()
                        Text("\(uncheckedCount) item\(uncheckedCount == 1 ? "" : "s") left")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(paperBackground)
            }

            ForEach(groupedDisplayedItems, id: \.0) { category, items in
                Section {
                    ForEach(items) { item in
                        ShoppingItemRow(
                            item: item,
                            isChecked: checkedItems.contains(item.id),
                            onToggle: { toggleCheck(item) }
                        )
                        .listRowBackground(paperBackground)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: category.icon)
                        Text(category.rawValue)
                    }
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(categoryColor(for: category))
                    .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
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
                .font(.system(.title2, design: .rounded).weight(.bold))

            Text(recipes.isEmpty
                    ? "Add recipes and link ingredients to generate your shopping list."
                    : "All your recipe ingredients are stocked up.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func toggleCheck(_ item: ShoppingItem) {
        if checkedItems.contains(item.id) {
            checkedItems.remove(item.id)
        } else {
            checkedItems.insert(item.id)
        }
    }

    private func categoryColor(for category: FoodCategory) -> Color {
        switch category {
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
}

// MARK: - Shopping Item Row

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
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .strikethrough(isChecked)
                    .foregroundStyle(isChecked ? .secondary : .primary)

                Text(item.recipes.prefix(2).joined(separator: ", "))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(item.neededQuantity.formatted()) \(item.unit.abbreviation)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
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
                                .font(.system(.body, design: .rounded))
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
