//
//  CreateRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

struct CreateRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModal]
    
    @State private var name: String = ""
    @State private var descriptionRecipe: String = ""
    @State private var duration: Decimal = 0.0
    @State private var ingredients: [RecipeFoodModal] = []
    @State private var steps: [String] = []
//    @State private var image: Data? = nil
    
    @State private var newStep: String = ""
    
    @State private var selectedFood: FoodModal? = nil
    @State private var quantityNeeded: Decimal = 0.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $descriptionRecipe)
                        .textInputAutocapitalization(.sentences)
                    
                    DecimalField(title: "Duration (minutes)", value: $duration)
                } header: {
                    Text("Details")
                }
                
                if !foods.isEmpty {
                    Section {
                        if !ingredients.isEmpty {
                            ForEach(ingredients) { ingredient in
                                if let ingredientInfo = ingredient.ingredient {
                                    HStack {
                                        Text(ingredientInfo.name)
                                    
                                        Text("\(ingredient.quantityNeeded) \(ingredientInfo.unit.abbreviation)")
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                ingredients.remove(atOffsets: indexSet)
                            }
                        }
                        
                        HStack {
                            Picker("Select Ingredient", selection: $selectedFood) {
                                ForEach(foods) { value in
                                    Text(value.name)
                                        .tag(value)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Button {
                                guard let food = selectedFood, quantityNeeded > 0 else { return }
                                
                                let newIngredient = RecipeFoodModal(ingredient: food, quantityNeeded: quantityNeeded)
                                
                                withAnimation {
                                    ingredients.append(newIngredient)
                                }
                                
                                selectedFood = foods.first
                                
                                quantityNeeded = 0.0
                            } label: {
                                Label("Add", systemImage: "plus.circle")
                                    .labelStyle(.iconOnly)
                                    .disabled(quantityNeeded == 0.0)
                            }
                            
                        }
                        
                        if let selectedFood = selectedFood {
                            DecimalField(title: "Quantity (\(selectedFood.unit.abbreviation))", value: $quantityNeeded)
                        }
                    } header: {
                        Text("Ingredients")
                    }
                }
                
                Section {
                    ForEach(steps, id: \ .self) { step in
                        Text(step)
                    }
                    .onDelete { indexSet in
                        steps.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add a step", text: $newStep)
                        
                        Button {
                            guard !newStep.isEmpty else { return }
                            
                            withAnimation {
                                steps.append(newStep)
                            }
                            
                            newStep = ""
                        } label: {
                            Label("Add", systemImage: "plus.circle")
                                .labelStyle(.iconOnly)
                                .disabled(newStep == "")
                        }
                    }
                } header: {
                    Text("Steps")
                }
                
//                Section {
//                    if let imageData = image, let uiImage = UIImage(data: imageData) {
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 200)
//                            .cornerRadius(8)
//                    } else {
//                        Text("No Image Selected")
//                            .foregroundColor(.gray)
//                    }
//                    
//                    Button("Select Image") {
//                        // Implement image picker logic here
//                    }
//                } header: {
//                    Text("Image")
//                }
            }
            .onAppear() {
                selectedFood = foods.first
            }
            .navigationTitle("Create Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem (placement: .topBarLeading, content: {
                    Button {
                        undoAndClose()
                    } label: {
                        Label("Undo", systemImage: "chevron.backward")
                            .labelStyle(.titleOnly)
                    }
                })
                
                ToolbarItem (placement: .topBarTrailing, content: {
                    Button {
                        saveRecipe()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .labelStyle(.titleOnly)
                    }
                })
            }
        }
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveRecipe() {
        let newRecipe = RecipeModal(
            name: name,
            descriptionRecipe: descriptionRecipe,
//            image: image,
//            ingredients: nil,
            steps: steps,
            duration: duration
        )
        
        newRecipe.rating = 0
        
        modelContext.insert(newRecipe)
        dismiss()
    }
}

#Preview {
    CreateRecipeView()
}
