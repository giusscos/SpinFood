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
    
    @Query var foods: [FoodModel]
    
    @Bindable var recipe: RecipeModel
    
    @State private var name: String = ""
    @State private var descriptionRecipe: String = ""
    @State private var duration: TimeInterval = 300.0
    @State private var ingredients: [RecipeFoodModel] = []
    @State private var stepInstructions: [String] = []
    @State private var stepImages: [Data?] = []
    @State private var imageItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    @State private var newStep: String = ""
    @State private var stepImageItem: PhotosPickerItem? = nil
    @State private var stepImageData: Data? = nil
    @State private var editingStepIndex: Int? = nil
    @State private var editedStepText: String = ""
    @State private var editedStepImageData: Data? = nil
    
    @State private var editingIngredientIndex: Int? = nil
    @State private var editedQuantity: Decimal = 0.0
    
    @State private var selectedFood: FoodModel? = nil
    @State private var quantityNeeded: Decimal = 0.0
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Group {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
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
                                            
                                            Text("Tap to Add Photo")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        .frame(height: 250)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .background(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottom))
                                    }
                                }
                        }
                    }
                } header: {
                    Text("Cover")
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .task(id: imageItem) {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                        withAnimation(.smooth) {
                            imageData = data
                        }
                    }
                }
                
                if imageData != nil {
                    Section {
                        PhotosPicker(selection: $imageItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                            Label("Update Image", systemImage: "photo")
                                .labelStyle(.titleOnly)
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                            .foregroundStyle(.secondary)
                        
                        TimePickerView(duration: $duration)
                    }
                } header: {
                    Text("Basic info")
                }
                
                if !foods.isEmpty {
                    Section {
                        if !ingredients.isEmpty {
                            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                if let ingredientInfo = ingredient.ingredient {
                                    if editingIngredientIndex == index {
                                        HStack {
                                            Text(ingredientInfo.name)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            TextField("Quantity", value: $editedQuantity, format: .number)
                                                .keyboardType(.decimalPad)
                                                .frame(maxWidth: 60)
                                                .onSubmit {
                                                    ingredients[index].quantityNeeded = editedQuantity
                                                    editingIngredientIndex = nil
                                                }
                                            
                                            Text(ingredientInfo.unit.abbreviation)
                                                .font(.headline)
                                                .foregroundStyle(.secondary)
                                                
                                            Button {
                                                ingredients[index].quantityNeeded = editedQuantity
                                                editingIngredientIndex = nil
                                            } label: {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.primary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.vertical, 4)
                                    } else {
                                        HStack {
                                            Text(ingredientInfo.name)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("\(ingredient.quantityNeeded) \(ingredientInfo.unit.abbreviation)")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                ingredients.remove(at: index)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                            Button {
                                                editingIngredientIndex = index
                                                editedQuantity = ingredient.quantityNeeded
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
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
                                
                                let newIngredient = RecipeFoodModel(ingredient: food, quantityNeeded: quantityNeeded)
                                
                                withAnimation {
                                    ingredients.append(newIngredient)
                                }
                                
                                selectedFood = foods.first
                                quantityNeeded = 0.0
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(quantityNeeded == 0.0 ? .secondary : .primary)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(quantityNeeded == 0.0)
                        }
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text("Ingredients")
                    }
                }
                
                Section {
                    ForEach(Array(stepInstructions.indices), id: \.self) { index in
                        if editingStepIndex == index {
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
                                    TextField("Edit step", text: $editedStepText, axis: .vertical)
                                        .padding(.vertical, 4)
                                        .autocorrectionDisabled()
                                        .onSubmit {
                                            stepInstructions[index] = editedStepText
                                            if let editedImage = editedStepImageData {
                                                if index < stepImages.count {
                                                    stepImages[index] = editedImage
                                                } else {
                                                    // Ensure stepImages array is large enough
                                                    while stepImages.count <= index {
                                                        stepImages.append(nil)
                                                    }
                                                    stepImages[index] = editedImage
                                                }
                                            }
                                            editingStepIndex = nil
                                        }
                                    
                                    Button {
                                        stepInstructions[index] = editedStepText
                                        if let editedImage = editedStepImageData {
                                            if index < stepImages.count {
                                                stepImages[index] = editedImage
                                            } else {
                                                // Ensure stepImages array is large enough
                                                while stepImages.count <= index {
                                                    stepImages.append(nil)
                                                }
                                                stepImages[index] = editedImage
                                            }
                                        }
                                        editingStepIndex = nil
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(editedStepText.isEmpty ? .secondary : .primary)
                                            .font(.title2)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(editedStepText.isEmpty)
                                }
                                
                                if let imageData = editedStepImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                PhotosPicker(selection: $stepImageItem,
                                         matching: .images,
                                         photoLibrary: .shared()) {
                                    Label(editedStepImageData == nil ? "Add Image" : "Change Image", systemImage: "photo")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .task(id: stepImageItem) {
                                    if let data = try? await stepImageItem?.loadTransferable(type: Data.self) {
                                        withAnimation(.smooth) {
                                            editedStepImageData = data
                                        }
                                    }
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(stepInstructions[index])
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)
                                
                                if index < stepImages.count, let imageData = stepImages[index], let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    stepInstructions.remove(at: index)
                                    if index < stepImages.count {
                                        stepImages.remove(at: index)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingStepIndex = index
                                    editedStepText = stepInstructions[index]
                                    if index < stepImages.count {
                                        editedStepImageData = stepImages[index]
                                    } else {
                                        editedStepImageData = nil
                                    }
                                    stepImageItem = nil
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            TextEditor(text: $newStep.animation(.spring()))
                                .frame(height: 80)
                                .fontWeight(.medium)
                                .autocorrectionDisabled()
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
                                
                                stepInstructions.append(newStep)
                                stepImages.append(stepImageData)
                                
                                newStep = ""
                                stepImageData = nil
                                stepImageItem = nil
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(newStep.isEmpty ? .secondary : .primary)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .disabled(newStep.isEmpty)
                        }
                        
                        if let imageData = stepImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        }
                        
                        PhotosPicker(selection: $stepImageItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                            Label(stepImageData == nil ? "Add Image to Step" : "Change Image", systemImage: "photo")
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 4)
                        .task(id: stepImageItem) {
                            if let data = try? await stepImageItem?.loadTransferable(type: Data.self) {
                                withAnimation(.smooth) {
                                    stepImageData = data
                                }
                            }
                        }
                    }
                } header: {
                    Text("Steps")
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
                
                stepInstructions = recipe.stepInstructions
                stepImages = recipe.stepImages
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
                    .disabled(name.isEmpty || imageData == nil)
                })
            }
        }
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveRecipe() {
        guard !name.isEmpty && imageData != nil else { return }
        
        recipe.name = name
        recipe.descriptionRecipe = descriptionRecipe
        recipe.ingredients = ingredients
        recipe.image = imageData
        recipe.stepInstructions = stepInstructions
        recipe.stepImages = stepImages
        recipe.duration = duration
        
        dismiss()
    }
}

#Preview {
    EditRecipeView(recipe: RecipeModel(name: "Carbonara", duration: 13))
}
