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
    case cookNow([StepRecipe])
    
    var id: String {
        switch self {
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        case .confirmEat:
            return "confirmEat"
        case .cookNow(let steps):
            return "cookNow-\(steps.count)"
        }
    }
}

struct RecipeDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var food: [FoodModel]
    
    @State private var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    @State private var listBackgroundColor: Color = Color(.systemBackground)
    
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
                        }
                    }
                    .frame(minHeight: size.height * 0.5)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    
                    if recipe.descriptionRecipe != "" {
                        Section {
                            VStack (alignment: .leading, spacing: 24) {
                                Text(recipe.name)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                
                                Text(recipe.descriptionRecipe)
                                    .multilineTextAlignment(.leading)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 32))
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    RecipeDetailsIngredientView(recipe: recipe, missingIngredients: missingIngredients)
                    
                    RecipeDetailsStepView(recipe: recipe)
                    
                    RecipeDetailsCookButtonView(recipe: recipe, hasAllIngredients: hasAllIngredients, activeRecipeDetailSheet: $activeRecipeDetailSheet)
                }
                .listStyle(.plain)
                .ignoresSafeArea(.container)
                .background(
                    listBackgroundColor
                        .ignoresSafeArea()
                )
                .fullScreenCover(item: $activeRecipeDetailSheet) { sheet in
                    switch sheet {
                    case .edit(let recipe):
                        EditRecipeView(recipe: recipe)
                    case .confirmEat:
                        RecipeConfirmEatView(recipe: recipe)
                    case .cookNow(let steps):
                        CookRecipeStepByStepView(recipe: recipe, steps: steps)
                    }
                }
                .navigationBarBackButtonHidden()
                .toolbarVisibility(.hidden, for: .tabBar)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Back")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .foregroundColor(.primary)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        .padding(.vertical)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeRecipeDetailSheet = .edit(recipe)
                        } label: {
                            Text("Edit")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .foregroundColor(.primary)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        .padding(.vertical)
                    }
                }
                .onAppear() {
                    if let imageData = recipe.image, let uiImage = UIImage(data: imageData), let avgColor = uiImage.averageColor() {
                        listBackgroundColor = Color(avgColor)
                    }
                }
            }
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModel(name: "Carbonara"))
}

struct RecipeDetailsCookButtonView: View {
    var recipe: RecipeModel
    var hasAllIngredients: Bool
    
    @Binding var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            Section {
                Button {
                    if hasAllIngredients {
                        if let steps = recipe.steps, !steps.isEmpty {
                            return activeRecipeDetailSheet = .cookNow(steps)
                        } else if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                                return activeRecipeDetailSheet = .confirmEat
                        }
                    }
                } label: {
                    Text("Cook")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!hasAllIngredients)
            }
            .padding(.bottom, 96)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}

struct RecipeDetailsStepView: View {
    var recipe: RecipeModel
    
    var body: some View {
        if let steps = recipe.steps, !steps.isEmpty {
            Section {
                VStack (alignment: .leading) {
                    HStack (alignment: .lastTextBaseline, spacing: 4) {
                        Group {
                            Text(steps.count == 1 ? "Step" : "Steps")
                            +
                            Text(":")
                        }
                        .font(.headline)
                        
                        Text(recipe.duration.formatted)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(.rect(cornerRadius: 32))
                    
                    ForEach(steps) { step in
                        VStack(alignment: .leading, spacing: 8) {
                            if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 220)
                                    .clipShape(.rect(cornerRadius: 20))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Text(step.text)
                                .padding(4)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 32))
                    }
                }
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}

struct RecipeDetailsIngredientView: View {
    var recipe: RecipeModel
    var missingIngredients: [RecipeFoodModel]
    
    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            Section {
                VStack (alignment: .leading) {
                    Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                        .font(.headline)
                        .padding(.bottom)
                    
                    ForEach(ingredients) { value in
                        if let ingredient = value.ingredient {
                            let missingIngredient = missingIngredients.contains(where: { $0.id == value.id })
                            HStack (alignment: .lastTextBaseline) {
                                Text(ingredient.name)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(value.quantityNeeded)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(missingIngredient ? .red : .primary)
                                +
                                Text("\(ingredient.unit.abbreviation)")
                                    .font(.subheadline)
                                    .foregroundStyle(missingIngredient ? .red : .secondary)

                            }
                            .lineLimit(1)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 32))
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}
