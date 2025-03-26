//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeDetailSheet: Identifiable {
    case edit(RecipeModel)
    case confirmEat
    
    var id: String {
        switch self {
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        case .confirmEat:
            return "confirmEat"
        }
    }
}

struct RecipeDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var food: [FoodModel]
    
    @State private var showConfirmEat: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    
    @State private var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    var recipe: RecipeModel
    
    var missingIngredients: [RecipeFoodModel] {
        guard let ingredients = recipe.ingredients else { return [] }
        
        return ingredients.filter { ingredient in
            guard let requiredIngredient = ingredient.ingredient else { return false }
            guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return true }
            
            return inventoryItem.currentQuantity < ingredient.quantityNeeded
        }
    }
    
    var hasAllIngredients: Bool {
        return missingIngredients.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let imageData = recipe.image,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .overlay (alignment: .bottom) {
                            Color.clear
                                .background(.thinMaterial)
                                .frame(maxWidth: .infinity)
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, .black, .clear]),
                                        startPoint: .bottom,
                                        endPoint: .center
                                    )
                                )
                                .overlay(alignment: .bottom) {
                                    VStack (alignment: .leading, spacing: 8) {
                                        VStack (alignment: .leading, spacing: 0) {
                                            Text(recipe.duration.formatted)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.secondary)
                                            
                                            Text(recipe.name)
                                                .font(.title)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .tint(.primary)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                        }
                }
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    VStack(spacing: 8) {
                        Button {
                            activeRecipeDetailSheet = .confirmEat
                        } label: {
                            Label("Cook now", systemImage: "frying.pan.fill")
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(hasAllIngredients ? Color.accentColor : Color.gray)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .disabled(!hasAllIngredients)
                        
                        if !hasAllIngredients {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Missing ingredients:")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                                
                                ForEach(missingIngredients) { missing in
                                    if let ingredient = missing.ingredient {
                                        HStack {
                                            Text("• \(ingredient.name)")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            if let inventoryItem = food.first(where: { $0.id == ingredient.id }) {
                                                Text("Have: \(inventoryItem.currentQuantity), Need: \(missing.quantityNeeded) \(ingredient.unit.abbreviation)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            } else {
                                                Text("Need: \(missing.quantityNeeded) \(ingredient.unit.abbreviation)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                        .foregroundStyle(.red)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                if recipe.descriptionRecipe != "" {
                    Section {
                        Text(recipe.descriptionRecipe)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } header: {
                        Text("Description")
                            .font(.title3)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    Section {
                        VStack (alignment: .leading) {
                            ForEach(ingredients) { value in
                                if let ingredient = value.ingredient {
                                    HStack{
                                        Text("\(ingredient.name):")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("\(value.quantityNeeded)\(ingredient.unit.abbreviation)")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                    }
                                    .lineLimit(1)
                                    .foregroundStyle(missingIngredients.contains(where: { $0.id == value.id }) ? .red : .primary)
                                }
                            }
                        }
                    } header: {
                        Text("Ingredients")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                if !recipe.steps.isEmpty {
                    Section {
                        ForEach(recipe.steps, id: \.self) { step in
                            Text("~ \(step);")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } header: {
                        Text("Steps")
                            .font(.title3)
                            .fontWeight(.medium)
                            .padding(.top)
                            .frame(maxWidth: .infinity, alignment: .leading)   
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(item: $activeRecipeDetailSheet) { sheet in
            switch sheet {
            case .edit(let value):
                EditRecipeView(recipe: value)
            case .confirmEat:
                if let ingredients = recipe.ingredients {
                    RecipeConfirmEatView(ingredients: ingredients, recipe: recipe)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeRecipeDetailSheet = .edit(recipe)
                    } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Recipe", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("Are you sure you want to delete \"\(recipe.name)\"? This action cannot be undone.")
        }
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModel(name: "Carbonara"))
}
