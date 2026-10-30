//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveFoodSheet: Identifiable {
    case details(FoodModel)
    case edit(FoodModel)
    case quickAdd
    case recipeIdeas

    var id: String {
        switch self {
        case .details(let food):
            return "detailsFood-\(food.id)"
        case .edit(let food):
            return "editFood-\(food.id)"
        case .quickAdd:
            return "quickAdd"
        case .recipeIdeas:
            return "recipeIdeas"
        }
    }
}

enum FoodSortOption {
    case nameAsc, nameDesc
    case quantityAsc, quantityDesc
    case dateAsc, dateDesc

    var label: String {
        switch self {
        case .nameAsc: return String(localized: "Name (A-Z)")
        case .nameDesc: return String(localized: "Name (Z-A)")
        case .quantityAsc: return String(localized: "Quantity (Low-High)")
        case .quantityDesc: return String(localized: "Quantity (High-Low)")
        case .dateAsc: return String(localized: "Date (Oldest first)")
        case .dateDesc: return String(localized: "Date (Newest first)")
        }
    }
}

enum FoodFilterOption {
    case all
    case lowStock
    case outOfStock
    case expiringSoon
    case expired

    var label: String {
        switch self {
        case .all: return String(localized: "All Food")
        case .lowStock: return String(localized: "Low Stock")
        case .outOfStock: return String(localized: "Out of Stock")
        case .expiringSoon: return String(localized: "Expiring Soon")
        case .expired: return String(localized: "Expired")
        }
    }
}

/// A one-tap stock change that can still be taken back, so a mistaken tap doesn't skew the stats.
private struct PendingStockUndo: Identifiable {
    let id = UUID()
    let message: String
    let revert: () -> Void
}

struct FoodView: View {
    @Environment(\.modelContext) var modelContext

    @Query var food: [FoodModel]

    @Namespace private var addFoodNamespace
    @Namespace private var foodRowNamespace

    @State private var activeSheet: ActiveFoodSheet?
    @State private var searchText = ""
    @State private var sortOption: FoodSortOption = .nameAsc
    @State private var filterOption: FoodFilterOption = .all
    @State private var selectedItems = Set<UUID>()
    @State private var isEditing = false
    @State private var showOutOfStock = false
    @State private var pendingUndo: PendingStockUndo?

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var filteredFood: [FoodModel] {
        var result = food

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch filterOption {
        case .all:
            break
        case .lowStock:
            result = result.filter { $0.currentQuantity < $0.quantity * 0.2 && $0.currentQuantity > 0 }
        case .outOfStock:
            result = result.filter { $0.currentQuantity <= 0 }
        case .expiringSoon:
            result = result.filter { $0.isExpiringSoon }
        case .expired:
            result = result.filter { $0.isExpired }
        }

        switch sortOption {
        case .nameAsc:
            result.sort { $0.name < $1.name }
        case .nameDesc:
            result.sort { $0.name > $1.name }
        case .quantityAsc:
            result.sort { $0.currentQuantity < $1.currentQuantity }
        case .quantityDesc:
            result.sort { $0.currentQuantity > $1.currentQuantity }
        case .dateAsc:
            result.sort { $0.createdAt < $1.createdAt }
        case .dateDesc:
            result.sort { $0.createdAt > $1.createdAt }
        }

        return result
    }

    /// Sections only make sense for the plain list; a search or filter already narrows it down.
    private var showsSections: Bool {
        searchText.isEmpty && filterOption == .all
    }

    private var useSoonFood: [FoodModel] {
        filteredFood
            .filter { !$0.isOutOfStock && ($0.isExpired || $0.isExpiringSoon) }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
    }

    private var inStockFood: [FoodModel] {
        filteredFood.filter { !$0.isOutOfStock && !$0.isExpired && !$0.isExpiringSoon }
    }

    private var outOfStockFood: [FoodModel] {
        filteredFood.filter(\.isOutOfStock)
    }

    var body: some View {
        List(selection: $selectedItems) {
            if food.isEmpty {
                emptyPantry
            } else if filteredFood.isEmpty {
                EmptyStateView(
                    symbol: "magnifyingglass",
                    title: "No matching food",
                    subtitle: "Try another search or filter"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if showsSections {
                if !useSoonFood.isEmpty {
                    Section {
                        foodRows(useSoonFood)
                    } header: {
                        useSoonHeader
                    }
                }

                if !inStockFood.isEmpty {
                    Section {
                        foodRows(inStockFood)
                    } header: {
                        sectionTitle("In stock")
                    }
                }

                if !outOfStockFood.isEmpty {
                    Section {
                        if showOutOfStock {
                            foodRows(outOfStockFood)
                        }
                    } header: {
                        outOfStockHeader
                    }
                }
            } else {
                foodRows(filteredFood)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            if let pendingUndo {
                undoBanner(pendingUndo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: pendingUndo?.id) {
            guard pendingUndo != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation { pendingUndo = nil }
        }
        .searchable(text: $searchText, prompt: "Search pantry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .quickAdd:
                QuickAddFoodView()
                    .navigationTransition(.zoom(sourceID: "addFood", in: addFoodNamespace))
            case .recipeIdeas:
                RecipeIdeasView()
            case .details(let food):
                FoodDetailsView(food: food)
                    .navigationTransition(.zoom(sourceID: food.id, in: foodRowNamespace))
            case .edit(let food):
                EditFoodView(food: food)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Inventory")
                    .font(.system(.title3, design: .serif).weight(.semibold))
            }

            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Done") {
                        withAnimation {
                            isEditing = false
                            selectedItems.removeAll()
                        }
                    }
                } else if !food.isEmpty {
                    Button("Edit") {
                        withAnimation { isEditing = true }
                    }
                }
            }

            if isEditing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        for id in selectedItems {
                            if let foodToDelete = food.first(where: { $0.id == id }) {
                                modelContext.delete(foodToDelete)
                            }
                        }
                        modelContext.saveConfirmedChanges()
                        selectedItems.removeAll()
                        withAnimation { isEditing = false }
                    } label: {
                        Label("Delete selected", systemImage: "trash")
                    }
                    .disabled(selectedItems.isEmpty)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .quickAdd
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .matchedTransitionSource(id: "addFood", in: addFoodNamespace)
                }

                if !food.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Menu {
                                Picker("Sort by", selection: $sortOption) {
                                    Text(FoodSortOption.nameAsc.label).tag(FoodSortOption.nameAsc)
                                    Text(FoodSortOption.nameDesc.label).tag(FoodSortOption.nameDesc)
                                    Divider()
                                    Text(FoodSortOption.quantityAsc.label).tag(FoodSortOption.quantityAsc)
                                    Text(FoodSortOption.quantityDesc.label).tag(FoodSortOption.quantityDesc)
                                    Divider()
                                    Text(FoodSortOption.dateAsc.label).tag(FoodSortOption.dateAsc)
                                    Text(FoodSortOption.dateDesc.label).tag(FoodSortOption.dateDesc)
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }

                            Menu {
                                Picker("Filter", selection: $filterOption) {
                                    Text(FoodFilterOption.all.label).tag(FoodFilterOption.all)
                                    Text(FoodFilterOption.lowStock.label).tag(FoodFilterOption.lowStock)
                                    Text(FoodFilterOption.outOfStock.label).tag(FoodFilterOption.outOfStock)
                                    Divider()
                                    Text(FoodFilterOption.expiringSoon.label).tag(FoodFilterOption.expiringSoon)
                                    Text(FoodFilterOption.expired.label).tag(FoodFilterOption.expired)
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            }
                        } label: {
                            Label("Menu", systemImage: "ellipsis")
                        }
                    }
                }
            }
        }
    }

    private func foodRows(_ rows: [FoodModel]) -> some View {
        ForEach(rows) { food in
            VStack(spacing: 0) {
                FoodRowView(food: food)

                if food.isExpired && !food.isOutOfStock && !isEditing {
                    expiredActions(for: food)
                }
            }
                .matchedTransitionSource(id: food.id, in: foodRowNamespace)
                .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onTapGesture {
                    if selectedItems.isEmpty {
                        activeSheet = .details(food)
                    }
                }
                // No full swipe: it would silently answer "used up" and under-report waste.
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if !food.isOutOfStock {
                        Button {
                            markUsedUp(food)
                        } label: {
                            Label("Used up", systemImage: "checkmark")
                        }
                        .tint(.green)

                        Button {
                            markThrownAway(food)
                        } label: {
                            Label("Thrown away", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(food)
                        modelContext.saveConfirmedChanges()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        activeSheet = .edit(food)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
        }
    }

    /// Expired food is the moment to log what really happened, so it asks instead of relying on a swipe.
    private func expiredActions(for food: FoodModel) -> some View {
        HStack(spacing: 8) {
            Button {
                markUsedUp(food)
            } label: {
                Label("Used it", systemImage: "checkmark")
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
            }
            .tint(.green)

            Button {
                markThrownAway(food)
            } label: {
                Label("Threw it away", systemImage: "trash")
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)
        }
        .font(.footnote.weight(.semibold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    private func markUsedUp(_ food: FoodModel) {
        let record = FoodConsumptionModel(quantity: food.currentQuantity, unit: food.unit, food: food)
        clearStock(of: food, loggedAs: record, message: String(localized: "\(food.name) marked as used"))
    }

    private func markThrownAway(_ food: FoodModel) {
        let record = FoodWasteModel(quantity: food.currentQuantity, food: food)
        clearStock(of: food, loggedAs: record, message: String(localized: "\(food.name) logged as thrown away"))
    }

    private func clearStock(of food: FoodModel, loggedAs record: any PersistentModel, message: String) {
        let previousQuantity = food.currentQuantity
        modelContext.insert(record)
        withAnimation { food.currentQuantity = 0 }
        modelContext.saveConfirmedChanges()
        withAnimation {
            pendingUndo = PendingStockUndo(message: message) {
                modelContext.delete(record)
                food.currentQuantity = previousQuantity
                modelContext.saveConfirmedChanges()
            }
        }
    }

    private func undoBanner(_ undo: PendingStockUndo) -> some View {
        HStack(spacing: 12) {
            Text(undo.message)
                .font(.subheadline)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button("Undo") {
                withAnimation {
                    undo.revert()
                    pendingUndo = nil
                }
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .capsule)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var emptyPantry: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                symbol: "cabinet",
                title: "No Ingredients",
                subtitle: "Tap what you have and Foo will warn you before it expires."
            )

            Button {
                activeSheet = .quickAdd
            } label: {
                Text("Add Food")
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(.subheadline, design: .serif).weight(.semibold))
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            .textCase(nil)
    }

    private var useSoonHeader: some View {
        HStack {
            Label("Use soon", systemImage: "clock.badge.exclamationmark")
                .font(.system(.subheadline, design: .serif).weight(.semibold))
                .foregroundStyle(.orange)
                .textCase(nil)

            Spacer()

            Button("Recipe ideas") {
                activeSheet = .recipeIdeas
            }
            .font(.system(.subheadline, design: .serif).weight(.medium))
            .textCase(nil)
        }
    }

    private var outOfStockHeader: some View {
        Button {
            withAnimation { showOutOfStock.toggle() }
        } label: {
            HStack(spacing: 6) {
                sectionTitle("Out of stock")
                Text("\(outOfStockFood.count)")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showOutOfStock ? 90 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FoodView()
}
