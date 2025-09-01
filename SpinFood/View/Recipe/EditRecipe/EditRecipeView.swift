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
    
    var recipe: RecipeModel?
    
    @State private var name: String = ""
    @State private var descriptionRecipe: String = ""
    @State private var duration: TimeInterval = 300.0
    @State private var ingredients: [RecipeFoodModel] = []
    @State private var imageItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var selectedFood: FoodModel?
    @State private var quantityNeeded: Decimal?
    
    @State private var steps: [StepRecipe] = []
    @State private var newStep: StepRecipe = StepRecipe(text: "")
    @State private var stepImageItem: PhotosPickerItem?
    
    @State private var showPhotoPicker: Bool = false
    @State private var showAdjustPhoto: Bool = false
    
    @State private var showDeleteConfirmation: Bool = false
    
    enum Field: Hashable {
        case name
        case recipeDescription
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            NavigationStack {
                VStack {
                    ScrollView {
                        VStack {
                            if !showAdjustPhoto {
                                EditRecipePhotoView(imageItem: $imageItem, imageData: $imageData, showPhotoPicker: $showPhotoPicker, showAdjustPhoto: $showAdjustPhoto , safeArea: safeArea, size: size)
                                
                                VStack {
                                    TextField("Name", text: $name)
                                        .autocorrectionDisabled()
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .focused($focusedField, equals: .name)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .recipeDescription
                                        }
                                    
                                    TextEditor(text: $descriptionRecipe)
                                        .textEditorStyle(.plain)
                                        .autocorrectionDisabled()
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .overlay(alignment: .topLeading, content: {
                                            if descriptionRecipe.isEmpty {
                                                Text("Add a description")
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 12)
                                            }
                                        })
                                        .frame(minHeight: 64, maxHeight: 256)
                                        .focused($focusedField, equals: .recipeDescription)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                }
                                .padding()
                                
                                VStack(alignment: .leading) {
                                    Text("Duration")
                                        .font(.headline)
                                    
                                    TimePickerView(duration: $duration)
                                }
                                .padding()
                                
                                EditRecipeIngredientView(foods: foods, ingredients: $ingredients, selectedFood: $selectedFood, quantityNeeded: $quantityNeeded)
                                
                                EditStepRecipeView(steps: $steps, newStep: $newStep, stepImageItem: $stepImageItem)
                            } else {
                                let height = size.height * 0.45
                                
                                GeometryReader { geometry in
                                    let size = geometry.size
                                    let minY = geometry.frame(in: .named("Scroll")).minY
                                    
                                    if let imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                                            .offset(y: (minY > 0 ? -minY : 0))
                                        
                                        // TODO: Add cropping/adjustment controls here, ensuring image can't exit frame
                                    }
                                }
                                .frame(height: height + safeArea.top)
                            }
                        }
                        .photosPicker(isPresented: $showPhotoPicker, selection: $imageItem, matching: .images, photoLibrary: .shared())
                    }
                    .coordinateSpace(name: "Scroll")
                }
                .ignoresSafeArea(.container, edges: .top)
                .background {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        let image = Image(uiImage: uiImage)
                        
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width * 1.3, height: size.height * 1.3)
                            .blur(radius: 64)
                            .scaleEffect(x: -1, y: 1)
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(colors: [.red, .indigo], startPoint: .topLeading, endPoint: .bottom)
                            .ignoresSafeArea()
                    }
                }
                .onAppear {
                    if let recipe = recipe {
                        name = recipe.name
                        descriptionRecipe = recipe.descriptionRecipe
                        imageData = recipe.image
                        duration = recipe.duration
                        ingredients = recipe.ingredients ?? []
                        steps = recipe.steps ?? []
                    }
                    
                    selectedFood = foods.first
                }
                .task(id: imageItem) {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let compressedData = uiImage.resizedAndCompressed() {
                        withAnimation(.smooth) {
                            imageData = compressedData
                        }
                    }
                }
                .toolbar {
                    if showAdjustPhoto {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showAdjustPhoto = false
                            } label: {
                                Label("Cancel", systemImage: "xmark")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            if #available(iOS 26, *) {
                                Button(role: .confirm) {
                                    // Save image adjustments here if needed
                                    showAdjustPhoto = false
                                } label: {
                                    Label("Save", systemImage: "checkmark")
                                }
                                .disabled(imageData == nil)
                            } else {
                                Button {
                                    // Save image adjustments here if needed
                                    showAdjustPhoto = false
                                } label: {
                                    Label("Save", systemImage: "checkmark")
                                }
                                .disabled(imageData == nil)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Label("Cancel", systemImage: "xmark")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            if #available(iOS 26, *) {
                                Button (role: .confirm) {
                                    saveRecipe()
                                } label: {
                                    Label("Save", systemImage: "checkmark")
                                }
                                .disabled(name.isEmpty || imageData == nil)
                            } else {
                                Button {
                                    saveRecipe()
                                } label: {
                                    Label("Save", systemImage: "checkmark")
                                }
                                .disabled(name.isEmpty || imageData == nil)
                            }
                        }
                        
                        if let _ = recipe {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button (role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .keyboard) {
                            Button {
                                hideKeyboard()
                            } label: {
                                Label("Hide Keyboard", systemImage: "keyboard.chevron.compact.down")
                            }
                        }
                    }
                }
                .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation, actions: {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete Recipe", role: .destructive) {
                        deleteRecipe()
                    }
                })
            }
        }
    }
    
    func saveRecipe() {
        guard !name.isEmpty && imageData != nil else { return }
        
        if let recipe = recipe {
            recipe.name = name
            recipe.descriptionRecipe = descriptionRecipe
            recipe.image = imageData
            recipe.ingredients = ingredients
            recipe.duration = duration
            recipe.steps = steps
        } else {
            let newRecipe = RecipeModel(
                name: name,
                descriptionRecipe: descriptionRecipe,
                image: imageData,
                duration: duration,
                ingredients: ingredients,
                steps: steps
            )
            
            modelContext.insert(newRecipe)
        }
        
        dismiss()
    }
    
    func deleteRecipe() {
        if let recipe = recipe {
            modelContext.delete(recipe)
            
            dismiss()
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    EditRecipeView()
}

