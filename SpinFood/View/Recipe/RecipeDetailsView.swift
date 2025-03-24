//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

enum ActiveRecipeDetailSheet: Identifiable {
    case edit(RecipeModal)
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
    
    @State private var showConfirmEat: Bool = false
    
    @State private var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    
    var recipe: RecipeModal
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let imageData = recipe.image,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, alignment: .center)
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
                    Button {
                        activeRecipeDetailSheet = .confirmEat
                    } label: {
                        Label("Cook now", systemImage: "frying.pan.fill")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .padding()
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
                    RecipeConfirmEatView(ingredients: ingredients)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    activeRecipeDetailSheet = .edit(recipe)
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .labelStyle(.titleOnly)
                }
            }
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModal(name: "Carbonara"))
}
