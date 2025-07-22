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
    @Binding var quantityNeeded: Decimal

    var body: some View {
        if !foods.isEmpty {
            Section {
                VStack {
                    if !ingredients.isEmpty {
                        Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(ingredients) { recipeIngridient in
                            if let ingridient = recipeIngridient.ingredient {
                                HStack (spacing: 16) {
                                    Text(ingridient.name)
                                        .font(.headline)
                                        .padding(4)
                                    
                                    Text("\(recipeIngridient.quantityNeeded)")
                                        .font(.headline)
                                    
                                    Text("\(ingridient.unit.abbreviation)")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
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
                                .padding(8)
                            }
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 32))
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            Section {
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
                                .frame(maxWidth: 64)
                            
                            Text(selectedFood.unit.abbreviation)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        guard let food = selectedFood, quantityNeeded > 0 else { return }
                        
                        let newIngredient = RecipeFoodModel(ingredient: food, quantityNeeded: quantityNeeded)
                        
                        withAnimation {
                            ingredients.append(newIngredient)
                        }
                        
                        selectedFood = foods.first
                        quantityNeeded = 0.0
                    } label: {
                        Text("Add ingredient")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(quantityNeeded == 0.0)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 32))
            }
            .listRowBackground(Color.clear)
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
