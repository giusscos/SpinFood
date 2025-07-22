//
//  RecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeSheet: Identifiable {
    case create
    case edit(RecipeModel)
    
    var id: String {
        switch self {
        case .create:
            return "createRecipe"
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        }
    }
}

enum RecipeSortOption {
    case nameAsc, nameDesc
    case dateAsc, dateDesc
    case durationAsc, durationDesc
    
    var label: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .dateAsc: return "Date (Oldest first)"
        case .dateDesc: return "Date (Newest first)"
        case .durationAsc: return "Duration (Shortest first)"
        case .durationDesc: return "Duration (Longest first)"
        }
    }
}

enum RecipeFilterOption {
    case all
    case canCook
    case cantCook
    
    var label: String {
        switch self {
        case .all: return "All Recipes"
        case .canCook: return "Ready to Cook"
        case .cantCook: return "Missing Ingredients"
        }
    }
}

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext
    
    @Namespace var namespace
    
    @Query var recipes: [RecipeModel]
    @Query var food: [FoodModel]
    
    @State private var activeRecipeSheet: ActiveRecipeSheet?
    @State private var searchText = ""
    @State private var sortOption: RecipeSortOption = .nameAsc
    @State private var filterOption: RecipeFilterOption = .all
    
    var filteredRecipes: [RecipeModel] {
        var result = recipes
        
        // Apply text search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply selected filter
        switch filterOption {
        case .all:
            break
        case .canCook:
            result = result.filter { recipe in
                guard let recipeIngredients = recipe.ingredients else { return false }
                
                return recipeIngredients.allSatisfy { recipeFood in
                    guard let requiredIngredient = recipeFood.ingredient else { return false }
                    guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                    
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
            }
        case .cantCook:
            result = result.filter { recipe in
                guard let recipeIngredients = recipe.ingredients else { return true }
                if recipeIngredients.isEmpty { return false }
                
                return !recipeIngredients.allSatisfy { recipeFood in
                    guard let requiredIngredient = recipeFood.ingredient else { return false }
                    guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                    
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
            }
        }
        
        // Apply selected sort
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
        
        List {
            if !filteredRecipes.isEmpty {
                ForEach(filteredRecipes) { value in
                    NavigationLink {
                        RecipeDetailsView(recipe: value)
                            .navigationTransition(.zoom(sourceID: value.id, in: namespace))
                    } label: {
                        RecipeRowView(recipe: value)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(value)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    activeRecipeSheet = .edit(value)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                    .matchedTransitionSource(id: value.id, in: namespace)
                }
            } else if searchText.isNotEmpty && filteredRecipes.isEmpty {
                ContentUnavailableView("No recipes found", systemImage: "magnifyingglass", description: Text("Try searching with different keywords"))
            } else {
                ContentUnavailableView("No recipe found", systemImage: "exclamationmark", description: Text("You can add your first recipe by clicking on the 'Plus' button"))
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .navigationTitle("Recipes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeRecipeSheet = .create
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .disabled(food.isEmpty)
            }
            
            ToolbarItem (placement: .topBarTrailing) {
                Menu {
                    if !recipes.isEmpty {
                        // Sort options
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
                        
                        // Filter options
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
                        
                        Divider()
                    }
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(item: $activeRecipeSheet, content: { sheet in
            switch sheet {
            case .create:
                EditRecipeView()
                    .interactiveDismissDisabled()
            case .edit(let value):
                EditRecipeView(recipe: value)
                    .interactiveDismissDisabled()
            }
        })
    }
}

#Preview {
    RecipeView()
}
