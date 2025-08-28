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
    @Query var foods: [FoodModel]
    
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
        GeometryReader { geometry in
            let size = geometry.size
            
            VStack {
                ScrollView (.horizontal, showsIndicators: false) {
                    if !filteredRecipes.isEmpty {
                        HStack(spacing: 16) {
                            ForEach(filteredRecipes) { recipe in
                                Group {
                                    NavigationLink {
                                        RecipeDetailsView(recipe: recipe)
                                            .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
                                    } label: {
                                        RecipeCardRowView(recipe: recipe, size: size)
                                    }
                                    .buttonStyle(.plain)
                                    .matchedTransitionSource(id: recipe.id, in: namespace)
                                }
                                .scrollTransition { content, phase in
                                    content
                                        .rotationEffect(phase.isIdentity ? .degrees(0) : .degrees(-12))
                                        .scaleEffect(phase.isIdentity ? 1 : 0.7)
                                        .blur(radius: phase.isIdentity ? 0 : 12)
                                }
                            }
                        }
                        .padding()
                        .scrollTargetLayout()
                    } else if !searchText.isEmpty && filteredRecipes.isEmpty {
                        ContentUnavailableView("No recipes found", systemImage: "magnifyingglass", description: Text("Try searching with different keywords"))
                    } else {
                        ContentUnavailableView("No recipe found", systemImage: "exclamationmark", description: Text("You can add your first recipe by clicking on the 'Plus' button"))
                    }
                }
                .scrollTargetBehavior(.viewAligned)
            }
            .searchable(text: $searchText, prompt: "Search recipe")
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeRecipeSheet = .create
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
}

#Preview {
    RecipeView()
}
