//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData
import TipKit

enum ActiveFoodSheet: Identifiable {
    case details(FoodModel)
    case edit(FoodModel)
    case create

    var id: String {
        switch self {
        case .details(let food):
            return "detailsFood-\(food.id)"
        case .edit(let food):
            return "editFood-\(food.id)"
        case .create:
            return "createFood"
        }
    }
}

enum FoodSortOption {
    case nameAsc, nameDesc
    case quantityAsc, quantityDesc
    case dateAsc, dateDesc

    var label: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .quantityAsc: return "Quantity (Low-High)"
        case .quantityDesc: return "Quantity (High-Low)"
        case .dateAsc: return "Date (Oldest first)"
        case .dateDesc: return "Date (Newest first)"
        }
    }
}

enum FoodFilterOption {
    case all
    case lowStock
    case outOfStock

    var label: String {
        switch self {
        case .all: return "All Food"
        case .lowStock: return "Low Stock"
        case .outOfStock: return "Out of Stock"
        }
    }
}

struct FoodView: View {
    @Environment(\.editMode) var editMode
    @Environment(\.modelContext) var modelContext

    @Query var food: [FoodModel]

    private let addFirstIngredientTip = AddFirstIngredientTip()

    @Namespace private var addFoodNamespace
    @Namespace private var foodRowNamespace

    @State private var activeSheet: ActiveFoodSheet?
    @State private var searchText = ""
    @State private var sortOption: FoodSortOption = .nameAsc
    @State private var filterOption: FoodFilterOption = .all
    @State private var selectedItems = Set<UUID>()

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

    var isEditMode: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        List(selection: $selectedItems) {
            if !filteredFood.isEmpty {
                ForEach(filteredFood) { food in
                    FoodRowView(food: food)
                        .matchedTransitionSource(id: food.id, in: foodRowNamespace)
                        .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            if selectedItems.isEmpty {
                                activeSheet = .details(food)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(food)
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
            } else {
                EmptyStateView(
                    symbol: "cabinet",
                    title: "No Ingredients",
                    subtitle: "Tap + to add your first ingredient"
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
        .searchable(text: $searchText, prompt: "Search pantry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                EditFoodView()
                    .navigationTransition(.zoom(sourceID: "addFood", in: addFoodNamespace))
            case .details(let food):
                FoodDetailsView(food: food)
                    .navigationTransition(.zoom(sourceID: food.id, in: foodRowNamespace))
            case .edit(let food):
                EditFoodView(food: food)
            }
        }
        .onAppear {
            AddFirstIngredientTip.hasIngredients = !food.isEmpty
        }
        .onChange(of: food.isEmpty) { _, isEmpty in
            AddFirstIngredientTip.hasIngredients = !isEmpty
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Inventory")
                    .font(.system(.title3, design: .serif).weight(.semibold))
            }

            if !food.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addFirstIngredientTip.invalidate(reason: .actionPerformed)
                    activeSheet = .create
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .matchedTransitionSource(id: "addFood", in: addFoodNamespace)
                .popoverTip(addFirstIngredientTip)
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
                            }
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            for id in selectedItems {
                                if let foodToDelete = food.first(where: { $0.id == id }) {
                                    modelContext.delete(foodToDelete)
                                }
                            }
                            selectedItems.removeAll()
                            editMode?.wrappedValue = .inactive
                        } label: {
                            Label("Delete selected", systemImage: "trash")
                        }
                        .disabled(selectedItems.isEmpty)
                    } label: {
                        Label("Menu", systemImage: "ellipsis")
                    }
                }
            }
        }
    }
}

#Preview {
    FoodView()
}
