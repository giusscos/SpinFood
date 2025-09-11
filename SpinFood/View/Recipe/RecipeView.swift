//
//  RecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeSheet: Identifiable {
    case createRecipe
    case edit(RecipeModel)
    case createFood
    
    var id: String {
        switch self {
        case .createRecipe:
            return "createRecipe"
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
            case .createFood:
                return "createFood"
        }
    }
}

struct RecipeView: View {
    enum RecipeSortOption {
        case nameAsc, nameDesc
        case dateAsc, dateDesc
        case durationAsc, durationDesc
        
        var label: String {
            switch self {
                case .nameAsc:
                    return "Name (A-Z)"
                case .nameDesc:
                    return "Name (Z-A)"
                case .dateAsc:
                    return "Date (Oldest first)"
                case .dateDesc:
                    return "Date (Newest first)"
                case .durationAsc:
                    return "Duration (Shortest first)"
                case .durationDesc:
                    return "Duration (Longest first)"
            }
        }
    }
    
    enum RecipeFilterOption {
        case all
        case canCook
        case cantCook
        
        var label: String {
            switch self {
                case .all:
                    return "All Recipes"
                case .canCook:
                    return "Ready to Cook"
                case .cantCook:
                    return "Missing Ingredients"
            }
        }
    }

    @Environment(\.modelContext) var modelContext
        
    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]
    
    @State private var activeRecipeSheet: ActiveRecipeSheet?
    @State private var sortOption: RecipeSortOption = .nameAsc
    @State private var filterOption: RecipeFilterOption = .all
    
    var filteredRecipes: [RecipeModel] {
        var result = recipes
        
        switch filterOption {
        case .all:
            break
        case .canCook:
            result = result.filter { recipe in
                guard let recipeIngredients = recipe.ingredients else { return false }
                
                return recipeIngredients.allSatisfy { recipeFood in
                    guard let requiredIngredient = recipeFood.ingredient else { return false }
                    guard let inventoryItem = foods.first(where: { $0.id == requiredIngredient.id }) else { return false }
                    
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
            }
        case .cantCook:
            result = result.filter { recipe in
                guard let recipeIngredients = recipe.ingredients else { return true }
                if recipeIngredients.isEmpty { return false }
                
                return !recipeIngredients.allSatisfy { recipeFood in
                    guard let requiredIngredient = recipeFood.ingredient else { return false }
                    guard let inventoryItem = foods.first(where: { $0.id == requiredIngredient.id }) else { return false }
                    
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
            }
        }
        
        switch sortOption {
        case .nameAsc:
            result.sort { $0.name < $1.name }
        case .nameDesc:
            result.sort { $0.name > $1.name }
        case .dateAsc:
            result.sort { $0.createdAt < $1.createdAt }
        case .dateDesc:
            result.sort { $0.createdAt > $1.createdAt }
        case .durationAsc:
            result.sort { $0.duration < $1.duration }
        case .durationDesc:
            result.sort { $0.duration > $1.duration }
        }
        
        return result
    }
    
    var body: some View {
        VStack {
            List {
                if filteredRecipes.isEmpty {
                    if foods.isEmpty {
                        Section {
                            VStack {
                                Text("No ingredient found 😕")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                Text("Insert ingredient to start create recipes")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    activeRecipeSheet = .createFood
                                } label: {
                                    Text("Add")
                                }
                                .tint(.accent)
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } else if recipes.isEmpty {
                        Section {
                            VStack {
                                Text("No recipe found 😕")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                Text("Insert recipe to start track your eating habits")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    activeRecipeSheet = .createRecipe
                                } label: {
                                    Text("Add")
                                }
                                .tint(.accent)
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                } else {
                    ForEach(filteredRecipes) { recipe in
                        Section {
                            RecipeRowView(recipe: recipe, activeRecipeSheet: $activeRecipeSheet)
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(recipe)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeRecipeSheet = .edit(recipe)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Recipes")
        .toolbarVisibility(.visible, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeRecipeSheet = .createRecipe
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .disabled(foods.isEmpty)
            }
            
            if !recipes.isEmpty {
                ToolbarItem (placement: .topBarTrailing) {
                    Menu {
                        if !recipes.isEmpty {
                            Menu {
                                Picker("Sort by", selection: $sortOption) {
                                    Text(RecipeSortOption.nameAsc.label)
                                        .tag(RecipeSortOption.nameAsc)
                                    
                                    Text(RecipeSortOption.nameDesc.label)
                                        .tag(RecipeSortOption.nameDesc)
                                    
                                    Divider()
                                    
                                    Text(RecipeSortOption.dateAsc.label)
                                        .tag(RecipeSortOption.dateAsc)
                                    
                                    Text(RecipeSortOption.dateDesc.label)
                                        .tag(RecipeSortOption.dateDesc)
                                    
                                    Divider()
                                    
                                    Text(RecipeSortOption.durationAsc.label)
                                        .tag(RecipeSortOption.durationAsc)
                                    
                                    Text(RecipeSortOption.durationDesc.label)
                                        .tag(RecipeSortOption.durationDesc)
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }
                            
                            Menu {
                                Picker("Filter", selection: $filterOption) {
                                    Text(RecipeFilterOption.all.label)
                                        .tag(RecipeFilterOption.all)
                                    
                                    Text(RecipeFilterOption.canCook.label)
                                        .tag(RecipeFilterOption.canCook)
                                    
                                    Text(RecipeFilterOption.cantCook.label)
                                        .tag(RecipeFilterOption.cantCook)
                                }
                            } label: {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            }
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis")
                    }
                }
            }
        }
        .fullScreenCover(item: $activeRecipeSheet, content: { sheet in
            switch sheet {
                case .createRecipe:
                    EditRecipeView()
                        .interactiveDismissDisabled()
                case .edit(let value):
                    EditRecipeView(recipe: value)
                        .interactiveDismissDisabled()
                case .createFood:
                    EditFoodView()
            }
        })
    }
}

#Preview {
    RecipeView()
}
