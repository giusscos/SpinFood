//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

struct RecipeDetailsView: View {
    @Environment(\.dismiss) var dismiss
    
    var recipe: RecipeModal
    
    @Query var food: [FoodModal]
    
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
                    
                    VStack (alignment: .leading) {
                        ForEach(recipe.steps, id: \.self) { step in
                            Text("~ \(step);")
                        }
                    }
                } header: {
                    Text("Steps")
                }
                
            }
            .navigationTitle(recipe.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        eatFood()
                    } label: {
                        Label("Eat", systemImage: "fork.knife.circle")
                    }
                }
            }
        }
    }
    
    func eatFood() {
        guard let recipeIngredients = recipe.ingredients else {
            print("La ricetta non ha ingredienti.")
            return
        }
        
        for recipeFood in recipeIngredients {
            guard let requiredIngredient = recipeFood.ingredient else { continue }
            
            // Trova l'ingrediente corrispondente nell'inventario
            if let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) {
                // Riduci la quantità di cibo
                inventoryItem.currentQuantity -= recipeFood.quantityNeeded
                if inventoryItem.currentQuantity < 0 {
                    inventoryItem.currentQuantity = 0 // Evita quantità negative
                }
            }
        }
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModal(name: "Carbonara"))
}
