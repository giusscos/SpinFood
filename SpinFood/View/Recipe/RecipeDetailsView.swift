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
                    
                    VStack (alignment: .leading) {
                        ForEach(recipe.steps, id: \.self) { step in
                            Text("~ \(step);")
                        }
                    }
                } header: {
                    Text("Steps")
                }
                
            }.navigationTitle(recipe.name)
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModal(name: "Carbonara"))
}
