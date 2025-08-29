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
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            NavigationStack {
                VStack {
                    ScrollView {
                        VStack {
                            let height = size.height * 0.45
                            
                            GeometryReader { geometry in
                                let size = geometry.size
                                let minY = geometry.frame(in: .named("Scroll")).minY
                                let progress = (minY > 0 ? minY : 0) / (height * 0.8)
                                
                                if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                                        .clipped()
                                        .mask(
                                            ZStack (alignment: .bottom) {
                                                Rectangle()
                                                    .fill(
                                                        .linearGradient(colors: [
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(1),
                                                            .black.opacity(0.75 - progress),
                                                            .black.opacity(0.50 - progress),
                                                            .black.opacity(0.25 - progress),
                                                            .black.opacity(0 - progress),
                                                        ], startPoint: .top, endPoint: .bottom)
                                                    )
                                            }
                                        )
                                        .offset(y: (minY > 0 ? -minY : 0))
                                }
                            }
                            .frame(height: height + safeArea.top)
                            
                            VStack {
                                VStack(spacing: 24) {
                                    Text(recipe.name)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.center)
                                    
                                    if recipe.descriptionRecipe != "" {
                                        Text(recipe.descriptionRecipe)
                                            .multilineTextAlignment(.leading)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding()
                            
                            RecipeDetailsIngredientView(recipe: recipe, missingIngredients: missingIngredients)
                            
                            RecipeDetailsStepView(recipe: recipe)
                            
                            RecipeDetailsCookButtonView(recipe: recipe, hasAllIngredients: hasAllIngredients, activeRecipeDetailSheet: $activeRecipeDetailSheet)
                        }
                    }
                    .coordinateSpace(name: "Scroll")
                }
                .ignoresSafeArea(.container, edges: .top)
                .background {
                    if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                        let image = Image(uiImage: uiImage)
                        
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width * 1.3, height: size.height * 1.3)
                            .blur(radius: 64)
                            .scaleEffect(x: -1, y: 1)
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(colors: [.red, .indigo], startPoint: .topLeading, endPoint: .bottom)
                            .ignoresSafeArea()
                    }
                }
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
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeRecipeDetailSheet = .edit(recipe)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
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
            .padding()
        }
    }
}

struct RecipeDetailsStepView: View {
    var recipe: RecipeModel
    
    var body: some View {
        if let steps = recipe.steps, !steps.isEmpty {
            VStack (alignment: .leading) {
                HStack (alignment: .lastTextBaseline, spacing: 4) {
                    Group {
                        Text(steps.count == 1 ? "Step" : "Steps")
                        +
                        Text(":")
                    }
                    
                    Text(recipe.duration.formatted)
                        .foregroundStyle(.secondary)
                }
                .font(.headline)
                
                ForEach(steps) { step in
                    VStack(alignment: .leading, spacing: 8) {
                        if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 400 : 220)
                                .clipShape(.rect(cornerRadius: 20))
                        }
                        
                        Text(step.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}

struct RecipeDetailsIngredientView: View {
    var recipe: RecipeModel
    var missingIngredients: [RecipeFoodModel]
    
    var body: some View {
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            VStack (alignment: .leading) {
                Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                    .font(.headline)
                
                VStack {
                    ForEach(ingredients) { value in
                        if let ingredient = value.ingredient {
                            let missingIngredient = missingIngredients.contains(where: { $0.id == value.id })
                            HStack (alignment: .lastTextBaseline) {
                                Text(ingredient.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(value.quantityNeeded, format: .number)
                                    .font(.headline)
                                    .foregroundStyle(missingIngredient ? .red : .primary)
                                +
                                Text(ingredient.unit.abbreviation)
                                    .font(.headline)
                                    .foregroundStyle(missingIngredient ? .red : .secondary)
                            }
                            .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical)
            }
            .padding()
        }
    }
}
