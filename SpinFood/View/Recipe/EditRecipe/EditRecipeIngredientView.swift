//
//  EditRecipeIngredientView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/07/25.
//

import SwiftUI

struct EditRecipeIngredientView: View {
    var foods: [FoodModel]
    
    @Binding var ingredients: [RecipeFoodModel]
    @Binding var selectedFood: FoodModel?
    @Binding var quantityNeeded: Decimal?

    var body: some View {
        if !foods.isEmpty {
            if !ingredients.isEmpty {
                VStack {
                    HStack {
                        Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                    }
                    
                    VStack (spacing: 12) {
                        ForEach(ingredients) { recipeIngridient in
                            if let ingridient = recipeIngridient.ingredient {
                                HStack (spacing: 16) {
                                    Text(ingridient.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(recipeIngridient.quantityNeeded, format: .number)
                                        .font(.headline)
                                    +
                                    Text(ingridient.unit.abbreviation)
                                        .foregroundStyle(.secondary)
                                    
                                    Button(role: .destructive) {
                                        withAnimation {
                                            ingredients.removeAll { $0.id == recipeIngridient.id }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .symbolRenderingMode(.palette)
                                            .imageScale(.large)
                                            .font(.headline)
                                    }
                                    .foregroundStyle(.white, .red)
                                    .buttonStyle(.borderless)
                                    .buttonBorderShape(.circle)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack (spacing: 6) {
                    Picker("Select Ingredient", selection: $selectedFood) {
                        ForEach(foods) { value in
                            Text(value.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .tag(value)
                        }
                    }
                    .tint(.primary)
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let selectedFood = selectedFood {
                        TextField("Quantity", value: $quantityNeeded, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 72)
                        
                        Text(selectedFood.unit.abbreviation)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                }
                
                Button {
                    guard let food = selectedFood, let quantityNeeded = quantityNeeded, quantityNeeded > 0 else { return }
                    
                    let newIngredient = RecipeFoodModel(ingredient: food, quantityNeeded: quantityNeeded)
                    
                    withAnimation {
                        ingredients.append(newIngredient)
                    }
                    
                    selectedFood = foods.first
                    self.quantityNeeded = nil
                } label: {
                    Text("Add ingredient")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .tint(.blue)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(quantityNeeded == 0.0)
            }
            .padding()
        }
    }
}

#Preview {
    EditRecipeIngredientView(
        foods: [FoodModel(name: "Carrots")],
        ingredients: .constant([RecipeFoodModel(ingredient: FoodModel(name: "Carrots"), quantityNeeded: 0.0)]),
        selectedFood: .constant(nil),
        quantityNeeded: .constant(0.0)
    )
}
