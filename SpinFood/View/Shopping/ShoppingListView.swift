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
    @State private var manuallyAdded: Set<UUID> = []
    @State private var showRecipePicker: Bool = false
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
        var items = allMainItems

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

    var coveredFoodIDs: Set<UUID> {
        Set(shoppingItems.map { $0.id })
    }

    var autoItems: [ShoppingItem] {
        foods.filter { food in
            !coveredFoodIDs.contains(food.id) &&
            food.quantity > 0 &&
            food.stockPercentage <= 0.05
        }.map { food in
            ShoppingItem(
                id: food.id,
                foodName: food.name,
                category: food.category,
                neededQuantity: food.quantity - food.currentQuantity,
                unit: food.unit,
                recipes: ["Low stock"]
            )
        }
    }

    var autoItemIDs: Set<UUID> {
        Set(autoItems.map { $0.id })
    }

    var manualItems: [ShoppingItem] {
        foods.filter { manuallyAdded.contains($0.id) }.map { food in
            ShoppingItem(
                id: food.id,
                foodName: food.name,
                category: food.category,
                neededQuantity: food.quantity - food.currentQuantity,
                unit: food.unit,
                recipes: []
            )
        }
    }

    var allMainItems: [ShoppingItem] {
        shoppingItems + autoItems + manualItems
    }

    var suggestedItems: [FoodModel] {
        foods.filter { food in
            !coveredFoodIDs.contains(food.id) &&
            !autoItemIDs.contains(food.id) &&
            !manuallyAdded.contains(food.id) &&
            food.quantity > 0 &&
            food.stockPercentage < 0.80
        }.sorted { $0.stockPercentage < $1.stockPercentage }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.hasActiveSubscription {
                    subscriberContent
                } else {
                    lockedContent
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shopping List")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                }
            }
        }
    }

    // MARK: - Subscriber content

    private var subscriberContent: some View {
        Group {
            shoppingList
        }
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
                        showRecipePicker = true
                    } label: {
                        Label(
                            selectedRecipes.isEmpty ? "Filter by Recipe" : "\(selectedRecipes.count) Recipe\(selectedRecipes.count == 1 ? "" : "s") Selected",
                            systemImage: "fork.knife"
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
                    Label("Menu", systemImage: "ellipsis")
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
    }

    // MARK: - Locked content

    private var lockedContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Shopping Lists")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .tracking(3)

                    Text("Premium Feature")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                        .tracking(3)
                        .textCase(.uppercase)
                }
                .padding(.top, 40)

                Image(systemName: "cart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange.opacity(0.85))

                VStack(spacing: 24) {
                    tocEntry(roman: "I",   title: "Auto-Generated List",  note: "From your recipe ingredients")
                    tocDivider
                    tocEntry(roman: "II",  title: "Filter by Recipe",     note: "Shop for specific meals")
                    tocDivider
                    tocEntry(roman: "III", title: "Smart Grouping",       note: "Sorted by category")
                    tocDivider
                    tocEntry(roman: "IV",  title: "One-Tap Refill",       note: "Restock with a single tap")
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal)
        }
        .scrollContentBackground(.hidden)
    }

    private func tocEntry(roman: String, title: String, note: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(roman)
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.body, design: .serif))

                Text(note)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(". . . . . . .")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .padding(.vertical, 11)
    }

    private var tocDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 0.5)
    }

    // MARK: - Shopping list

    private var shoppingList: some View {
        List {
            if foods.isEmpty {
                Section {
                    EmptyStateView(
                        symbol: "cabinet",
                        title: "No Ingredients",
                        subtitle: "Add ingredients and link them to recipes to generate your shopping list."
                    )
                    .listRowBackground(paperBackground)
                }
            } else if displayedItems.isEmpty {
                Section {
                    EmptyStateView(
                        symbol: "checkmark.rectangle.stack.fill",
                        title: "All Stocked Up",
                        subtitle: "All your ingredients are well stocked."
                    )
                    .listRowBackground(paperBackground)
                }
            }

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

            if !suggestedItems.isEmpty {
                Section {
                    ForEach(suggestedItems) { food in
                        SuggestedFoodRow(food: food) {
                            manuallyAdded.insert(food.id)
                        }
                        .listRowBackground(paperBackground)
                    }
                } header: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("Suggested")
                    }
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.orange)
                    .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
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

// MARK: - Suggested Food Row

struct SuggestedFoodRow: View {
    let food: FoodModel
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.system(.body, design: .rounded).weight(.medium))

                Text("\(Int(food.stockPercentage * 100))% remaining")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(food.currentQuantity.formatted()) / \(food.quantity.formatted()) \(food.unit.abbreviation)")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)

            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
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
