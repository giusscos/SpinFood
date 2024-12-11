//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct RecipeDetailsView: View {
    @Environment(\.dismiss) var dismiss
    
    var recipe: RecipeModal
    
    var body: some View {
        NavigationStack{
            List {
                if let ingredients = recipe.ingredients {
                    Section {
                        VStack (alignment: .leading) {
                            ForEach(ingredients) { ingredient in
                                if let ingredient = ingredient.ingredient {
                                    HStack{
                                        Text("\(ingredient.name):")
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text("\(ingredient.quantity) \(ingredient.unit.abbreviation)")
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
                    
                    Text(recipe.descriptionRecipe)
                        .multilineTextAlignment(.leading)
                } header: {
                    Text("Info")
                }
                
            }.navigationTitle(recipe.name)
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModal(name: "Carbonara"))
}
