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
    case cookNow(RecipeModel)
    
    var id: String {
        switch self {
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        case .confirmEat:
            return "confirmEat"
        case .cookNow(let recipe):
            return "cookNow-\(recipe.id)"
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
            GeometryReader { geometry in
                let size = geometry.size
                
                List {
                    Section {
                        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: size.height * 0.5)
                                .mask(
                                    LinearGradient(colors: [.black, .black, .black, .black, .clear, .clear], startPoint: .top, endPoint: .bottom)
                                        .blur(radius: 16)
                                )
                                .overlay(alignment: .bottom) {
                                    Text(recipe.name)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .padding(.bottom, 32)
                                        .multilineTextAlignment(.center)
                                }
                        }
                    }
                    .frame(minHeight: size.height * 0.5)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        Section {
                            Button {
                                if hasAllIngredients {
                                    activeRecipeDetailSheet = .cookNow(recipe)
                                } else {
                                    activeRecipeDetailSheet = .confirmEat
                                }
                            } label: {
                                Label("Start cooking", systemImage: "frying.pan.fill")
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(hasAllIngredients ? Color.purple : Color.gray)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .disabled(!hasAllIngredients)
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    
                    if recipe.descriptionRecipe != "" {
                        Section {
                            Text(recipe.descriptionRecipe)
                                .multilineTextAlignment(.leading)
                                .font(.headline)
                        } header: {
                            Text("Description")
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
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
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    
                    if let steps = recipe.steps, !steps.isEmpty {
                        Section {
                            ForEach(steps) { step in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(step.text)
                                        .font(.headline)
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        } header: {
                            Text("Steps")
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .ignoresSafeArea(.container)
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
                case .cookNow(let value):
                    CookRecipeStepByStepView(recipe: value, onComplete: {
                        // When cooking is complete, show the confirm eat sheet and reset lastStepIndex
                        value.lastStepIndex = 0 // Reset step index
                        
                        if recipe.ingredients != nil {
                            self.activeRecipeDetailSheet = .confirmEat
                        }
                    })
                    .presentationDragIndicator(.visible)
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
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModel(name: "Carbonara"))
}
