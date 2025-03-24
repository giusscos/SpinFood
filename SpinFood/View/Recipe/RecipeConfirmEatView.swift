//
//  RecipeConfirmEatView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import SwiftUI
import SwiftData

struct RecipeConfirmEatView: View {
    @Environment(\.dismiss) var dismiss
    
    @Query var food: [FoodModel]
    
    var ingredients: [RecipeFoodModel]
    var recipe: RecipeModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center) {
                        Text("Are you sure?")
                            .font(.headline)
                        
                        Text("This are the ingredients you will consume:")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                
                Section {
                    ForEach(ingredients) { value in
                        if let food = value.ingredient {
                            HStack {
                                Text(food.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 2) {
                                    Text("\(value.quantityNeeded)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(food.unit.abbreviation)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Ingredients")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") {
                        confirmRecipe()
                    }
                }
            }
        }
    }
    
    func confirmRecipe() {
        for ingredient in ingredients {
            if let food = ingredient.ingredient {
                food.currentQuantity -= ingredient.quantityNeeded
                food.eatenAt.append(Date())
            }
        }
        
        recipe.cookedAt.append(Date())
        
        dismiss()
    }
}

#Preview {
    RecipeConfirmEatView(ingredients: [], recipe: RecipeModel(name: "Carbonara"))
}
