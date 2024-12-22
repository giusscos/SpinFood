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
    
    @Query var food: [FoodModal]
    
    var ingredients: [RecipeFoodModal]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text("Are you sure?")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This are the ingredients you will eat:")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        eatFood()
                        
                    } label: {
                        Label("Confirm", systemImage: "checkmark")
                    }
                }
            }
        }
    }
    
    func eatFood() {
        for recipeFood in ingredients {
            guard let requiredIngredient = recipeFood.ingredient else { continue }
            
            if let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) {
                inventoryItem.currentQuantity -= recipeFood.quantityNeeded
                
                if inventoryItem.currentQuantity < 0 {
                    inventoryItem.currentQuantity = 0
                }
            }
        }
    }
}

#Preview {
    RecipeConfirmEatView(ingredients: [])
}
