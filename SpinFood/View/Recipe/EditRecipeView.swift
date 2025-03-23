//
//  EditRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModal]
    
    @Bindable var recipe: RecipeModal
    
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
            List {
                Section {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .overlay (alignment: .bottomTrailing) {
                                Menu {
                                    Button(role: .destructive) {
                                        withAnimation(.smooth) {
                                            imageItem = nil
                                            self.imageData = nil
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                    
                                    PhotosPicker(selection: $imageItem,
                                                 matching: .images,
                                                 photoLibrary: .shared()) {
                                        Label("Update", systemImage: "photo")
                                    }
                                } label: {
                                    Label("Edit photo", systemImage: "pencil")
                                        .labelStyle(.titleOnly)
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                                .padding()
                            }
                            .frame(height: 250)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        PhotosPicker(
                            selection: $imageItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                                Group {
                                    VStack {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 50)
                                            .foregroundStyle(.white)
                                            .padding()
                                    }
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottom))
                                }
                            }
                    }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .task(id: imageItem) {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                        withAnimation(.smooth) {
                            imageData = data
                        }
                    }
                }
                
                Section {
                    TextField("Name", text: $name)
                        .font(.title)
                        .fontWeight(.bold)
                        .autocorrectionDisabled()
                        .padding(.top, 8)
                    
                    TextEditor(text: $descriptionRecipe.animation(.spring()))
                        .fontWeight(.medium)
                        .overlay(alignment: .topLeading, content: {
                            VStack {
                                if descriptionRecipe.isEmpty {
                                    Text("Add a good recipe description.")
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.leading, 4)
                        })
                    
                    
                    VStack(alignment: .leading) {
                        Text("Select duration")
                            .font(.headline)
                            .foregroundStyle(.primary.opacity(0.7))
                        
                        TimePickerView(duration: $duration)
                    }
                }
                
                if !foods.isEmpty {
                    Section {
                        Label("Ingredients", systemImage: "list.bullet")
                            .labelStyle(.titleOnly)
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.7))
                        
                        if !ingredients.isEmpty {
                            ForEach(ingredients) { ingredient in
                                if let ingredientInfo = ingredient.ingredient {
                                    HStack {
                                        Text(ingredientInfo.name)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("\(ingredient.quantityNeeded) \(ingredientInfo.unit.abbreviation)")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
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
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let selectedFood = selectedFood {
                                TextField("Quantity", value: $quantityNeeded, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(maxWidth: 60)
                                
                                Text(selectedFood.unit.abbreviation)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button {
                                guard let food = selectedFood, quantityNeeded > 0 else { return }
                                
                                let newIngredient = RecipeFoodModal(ingredient: food, quantityNeeded: quantityNeeded)
                                
                                withAnimation {
                                    ingredients.append(newIngredient)
                                }
                                
                                selectedFood = foods.first
                                quantityNeeded = 0.0
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(quantityNeeded == 0.0 ? .secondary : .white)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(quantityNeeded == 0.0)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section {
                    Label("Steps", systemImage: "list.number")
                        .labelStyle(.titleOnly)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ForEach(steps, id: \.self) { step in
                        Text(step)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        steps.remove(atOffsets: indexSet)
                    }
                    
                    HStack (alignment: .top) {
                        TextEditor(text: $newStep.animation(.spring()))
                            .frame(height: 80)
                            .fontWeight(.medium)
                            .overlay(alignment: .topLeading, content: {
                                VStack {
                                    if newStep.isEmpty {
                                        Text("Add a step...")
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.leading, 4)
                            })
                        
                        Button {
                            guard !newStep.isEmpty else { return }
                            
                            withAnimation {
                                steps.append(newStep)
                            }
                            
                            newStep = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(newStep.isEmpty ? .secondary : .white)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .disabled(newStep.isEmpty)
                    }
                }
            }
            .onAppear() {
                selectedFood = foods.first

                imageData = recipe.image
                name = recipe.name
                descriptionRecipe = recipe.descriptionRecipe
                
                if let recipeIngredients = recipe.ingredients {
                    ingredients = recipeIngredients
                }
                
                duration = recipe.duration
                
                steps = recipe.steps
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem (placement: .topBarLeading, content: {
                    Button {
                        undoAndClose()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .labelStyle(.titleOnly)
                    }
                })
                
                ToolbarItem (placement: .topBarTrailing, content: {
                    Button {
                        saveRecipe()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
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
        recipe.name = name
        recipe.descriptionRecipe = descriptionRecipe
        recipe.ingredients = ingredients
        recipe.image = imageData
        recipe.steps = steps
        recipe.duration = duration
        
        dismiss()
    }
}

#Preview {
    EditRecipeView(recipe: RecipeModal(name: "Carbonara", duration: 13))
}
