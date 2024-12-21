//
//  CreateRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CreateRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModal]
    
    @State private var name: String = ""
    @State private var descriptionRecipe: String = ""
    @State private var duration: TimeInterval = 300.0
    @State private var ingredients: [RecipeFoodModal] = []
    @State private var steps: [String] = []
    @State private var imageItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    @State private var newStep: String = ""
    
    @State private var selectedFood: FoodModal? = nil
    @State private var quantityNeeded: Decimal = 0.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(
                        selection: $imageItem,
                        matching: .images,
                        photoLibrary: .shared()) {
                            Group {
                                if let imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Label("Select an image", systemImage: "photo")
                                        .tint(Color.primary)
                                        .padding(.horizontal)
                                }
                            }
                            .frame(maxHeight: 100)
                            .frame(minHeight: 75)
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .task(id: imageItem) {
                            if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                                withAnimation {
                                    imageData = data
                                }
                            }
                        }
                    
                    if imageData != nil {
                        Button (role: .destructive) {
                            withAnimation {
                                imageItem = nil
                                imageData = nil
                            }
                        } label: {
                            Label("Remove image", systemImage: "minus.circle.fill")
                                .labelStyle(.titleOnly)
                        }
                        
                    }
                } header: {
                    Text("Cover")
                }
                
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.sentences)
                               
                    VStack (alignment: .leading) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    
                        TimePickerView(duration: $duration)
                    }
                    
                    VStack (alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $descriptionRecipe)
                            .frame(maxWidth: .infinity, minHeight: 50, maxHeight: 150, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.secondary, lineWidth: 1)
                            )
                            .padding(.bottom, 8)
                    }
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
                        TextEditor(text: $newStep)
                            .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .lineLimit(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.secondary, lineWidth: 1)
                            )
                        
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
                    .padding(.vertical, 8)
                } header: {
                    Text("Steps")
                }
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
            image: imageData,
            ingredients: ingredients,
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
