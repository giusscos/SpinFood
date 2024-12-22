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
        NavigationStack{
            List {
                Section {
                    if let imageData = recipe.image,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }
                }
                
                Section {
                    HStack {
                        Text("Created at ")
                        
                        Text(recipe.createdAt, format: .dateTime.day().month().year())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.headline)
                    
                    Text(recipe.descriptionRecipe)
                        .multilineTextAlignment(.leading)
                } header: {
                    Text("Info")
                }
                
                if let ingredients = recipe.ingredients {
                    Section {
                        VStack (alignment: .leading) {
                            ForEach(ingredients) { value in
                                if let ingredient = value.ingredient {
                                    HStack{
                                        Text("\(ingredient.name):")
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text("\(value.quantityNeeded) \(ingredient.unit.abbreviation)")
                                    }
                                    .lineLimit(1)
                                    .font(.headline)
                                }
                            }
                        }
                    } header: {
                        Text("Ingredients")
                    }
                }
                
                Section {
                    HStack {
                        Text("Duration: ")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(recipe.duration.formatted)
                    }
                    .font(.headline)
                    
                    ForEach(recipe.steps, id: \.self) { step in
                        Text("~ \(step);")
                    }
                } header: {
                    Text("Steps")
                }
                
            }
            .navigationTitle(recipe.name)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeRecipeDetailSheet = .edit(recipe)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeRecipeDetailSheet = .confirmEat
                    } label: {
                        Label("Eat", systemImage: "fork.knife.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModal(name: "Carbonara"))
}
