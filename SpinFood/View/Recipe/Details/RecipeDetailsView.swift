//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeDetailSheet: Identifiable {
    case confirmEat
    case cookNow([StepRecipe])
    
    var id: String {
        switch self {
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
    
    @State private var showDeleteConfirmation: Bool = false
    
    var recipe: RecipeModel
        
    var onEdit: () -> Void = {}
    
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
                            
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.headline)
                                
                                if recipe.descriptionRecipe != "" {
                                    Text(recipe.descriptionRecipe)
                                }
                            }
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            
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
                        case .confirmEat:
                            RecipeConfirmEatView(recipe: recipe)
                        case .cookNow(let steps):
                            CookRecipeStepByStepView(recipe: recipe, steps: steps)
                    }
                }
                .navigationBarBackButtonHidden()
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if  #available(iOS 26, *) {
                            Button(role: .cancel) {
                                dismiss()
                            } label: {
                                Label("Back", systemImage: "chevron.left")
                            }
                        } else {
                            Button(role: .cancel) {
                                dismiss()
                            } label: {
                                Label("Back", systemImage: "chevron.left.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.background, .gray)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if  #available(iOS 26, *) {
                            Button {
                                handleEditButton()
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        } else {
                            Button {
                                handleEditButton()
                            } label: {
                                Label("Edit", systemImage: "pencil.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.background, .accent)
                            }
                        }
                    }
                    
                    if #available(iOS 26, *) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button (role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button (role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.background, .red)
                            }
                        }
                    }
                }
                .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation, actions: {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete Recipe", role: .destructive) {
                        deleteRecipe()
                    }
                })
            }
        }
    }
    
    func deleteRecipe() {
        modelContext.delete(recipe)
        
        dismiss()
    }
    
    func handleEditButton() {
        onEdit()
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModel(name: "Carbonara"))
}


