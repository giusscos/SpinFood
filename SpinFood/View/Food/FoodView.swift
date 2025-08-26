//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveFoodSheet: Identifiable {
    case edit(FoodModel)
    case refillMulti
    case refillSelected([FoodModel])
    case create
    
    var id: String {
        switch self {
        case .edit(let food):
            return "editFood-\(food.id)"
        case .refillMulti:
            return "refillFood"
        case .refillSelected:
            return "refillSelected"
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
    
    @State private var activeSheet: ActiveFoodSheet?
    @State private var searchText = ""
    @State private var sortOption: FoodSortOption = .nameAsc
    @State private var filterOption: FoodFilterOption = .all
    @State private var selectedItems = Set<UUID>()
    
    var filteredFood: [FoodModel] {
        var result = food
        
        // Apply text search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply selected filter
        switch filterOption {
        case .all:
            break
        case .lowStock:
            result = result.filter { $0.currentQuantity < $0.quantity * 0.2 && $0.currentQuantity > 0 }
        case .outOfStock:
            result = result.filter { $0.currentQuantity <= 0 }
        }
        
        // Apply selected sort
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
    
    var foodToBeRefilled: [FoodModel] {
        food.filter { $0.currentQuantity < $0.quantity }
    }
    
    var allFoodToBeRefilled: Bool {
        foodToBeRefilled.count > 0
    }
    
    var body: some View {
        List(selection: $selectedItems) {
            if !filteredFood.isEmpty {
                ForEach(filteredFood) { food in
                    FoodRowView(food: food)
                        .onTapGesture {
                            if selectedItems.isEmpty {
                                activeSheet = .edit(food)
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
            }
            else if !searchText.isEmpty && filteredFood.isEmpty {
                ContentUnavailableView("No food found", systemImage: "magnifyingglass", description: Text("Try searching with different keywords"))
            } else {
                ContentUnavailableView("No food found", systemImage: "exclamationmark", description: Text("You can add your first food by clicking on the Add button"))
            }
        }
        .searchable(text: $searchText, prompt: "Search food")
        .navigationTitle("Food")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .create:
                EditFoodView()
            case .edit(let food):
                EditFoodView(food: food)
            case .refillMulti:
                NavigationStack {
                    FoodRefillView(food: foodToBeRefilled)
                        .presentationDragIndicator(.visible)
                }
            case .refillSelected(let selectedFood):
                NavigationStack {
                    FoodRefillView(food: selectedFood)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .toolbar {
            if !food.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeSheet = .create
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
            if !food.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if !food.isEmpty {
                            Menu {
                                Picker("Sort by", selection: $sortOption) {
                                    Text(FoodSortOption.nameAsc.label)
                                        .tag(FoodSortOption.nameAsc)
                                    
                                    Text(FoodSortOption.nameDesc.label)
                                        .tag(FoodSortOption.nameDesc)
                                    
                                    Divider()
                                    
                                    Text(FoodSortOption.quantityAsc.label)
                                        .tag(FoodSortOption.quantityAsc)
                                    
                                    Text(FoodSortOption.quantityDesc.label)
                                        .tag(FoodSortOption.quantityDesc)
                                    
                                    Divider()
                                    
                                    Text(FoodSortOption.dateAsc.label)
                                        .tag(FoodSortOption.dateAsc)
                                    
                                    Text(FoodSortOption.dateDesc.label)
                                        .tag(FoodSortOption.dateDesc)
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }
                            
                            Menu {
                                Picker("Filter", selection: $filterOption) {
                                    Text(FoodFilterOption.all.label)
                                        .tag(FoodFilterOption.all)
                                    
                                    Text(FoodFilterOption.lowStock.label)
                                        .tag(FoodFilterOption.lowStock)
                                    
                                    Text(FoodFilterOption.outOfStock.label)
                                        .tag(FoodFilterOption.outOfStock)
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            
                            Divider()
                            
                            Button {
                                activeSheet = .refillMulti
                            } label: {
                                Label("Refill all food", systemImage: "bag.fill.badge.plus")
                            }
                            .disabled(!allFoodToBeRefilled)
                            
                            Button {
                                let selectedFood = food.filter { selectedItems.contains($0.id) }
                                
                                activeSheet = .refillSelected(selectedFood)
                            } label: {
                                Label("Refill Selected", systemImage: "cart.fill.badge.plus")
                            }
                            .disabled(selectedItems.isEmpty)
                            
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
                        }
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
