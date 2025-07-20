//
//  EditRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - UIImage Extension for Average Color
extension UIImage {
    func averageColor() -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let parameters = [kCIInputExtentKey: CIVector(cgRect: extent)]
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: parameters) else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        guard let outputImage = filter.outputImage else { return nil }
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)
        return UIColor(red: CGFloat(bitmap[0]) / 255.0,
                       green: CGFloat(bitmap[1]) / 255.0,
                       blue: CGFloat(bitmap[2]) / 255.0,
                       alpha: 1.0)
    }
    
    // Ridimensiona e comprime l'immagine
    func resizedAndCompressed(maxDimension: CGFloat = 1024, compressionQuality: CGFloat = 0.7) -> Data? {
        let size = self.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.7)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage?.jpegData(compressionQuality: compressionQuality)
    }
}

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
        
    @Query var foods: [FoodModel]
    
    var recipe: RecipeModel?
    
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
    
    @State private var selectedFood: FoodModel? = nil
    @State private var quantityNeeded: Decimal = 0.0
    @State private var listBackgroundColor: Color = Color(.systemBackground)
    @State private var showPhotoPicker = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let size = geometry.size
                
                List {
                    Section {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: size.height * 0.5)
                                .clipShape(.circle)
                                .mask(
                                    RadialGradient(
                                        colors: [.black, .black, .black, .black, .clear, .clear],
                                        center: .center,
                                        startRadius: 120,
                                        endRadius: 140
                                    )
                                    .blur(radius: 16)
                                )
                                .overlay (alignment: .bottom, content: {
                                    Menu {
                                        Button {
                                            withAnimation {
                                                self.imageData = nil
                                                imageItem = nil
                                            }
                                        } label: {
                                            Label("Remove Photo", systemImage: "xmark")
                                        }
                                        
                                        Button {
                                            showPhotoPicker = true
                                        } label: {
                                            Label("Update Photo", systemImage: "photo")
                                        }
                                    } label: {
                                        Text("Edit Photo")
                                            .font(.headline)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .foregroundColor(.primary)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.capsule)
                                    .padding(.vertical)
                                })
                        } else {
                            Button {
                                showPhotoPicker = true
                            } label: {
                                VStack (spacing: 16) {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .clipShape(.circle)
                                    
                                    Text("Add Photo")
                                        .font(.headline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(.ultraThinMaterial)
                                        .clipShape(.capsule)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(minHeight: size.height * 0.45)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    Section {
                        VStack (spacing: 16) {
                            TextField("Name", text: $name)
                                .autocorrectionDisabled()
                                .font(.title)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading) {
                                Text("Description")
                                    .font(.headline)
                                
                                TextEditor(text: $descriptionRecipe)
                                    .textEditorStyle(.plain)
                                    .autocorrectionDisabled()
                                    .overlay(content: {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.tertiary, lineWidth: 1)
                                    })
                                
                                    .frame(minHeight: 32)
                                    .frame(maxHeight: 127)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 32))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    Section {
                        VStack(alignment: .leading) {
                            Text("Select duration")
                                .font(.headline)
                            
                            TimePickerView(duration: $duration)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(.rect(cornerRadius: 32))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    
                    if !foods.isEmpty {
                        Section {
                            if !ingredients.isEmpty {
                                Text(ingredients.count == 1 ? "Ingredient" : "Ingredients")
                                    .font(.headline)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(.capsule)
                                
                                ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                                    if let ingredientInfo = ingredient.ingredient {
                                        HStack {
                                            Text(ingredientInfo.name)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("\(ingredient.quantityNeeded) \(ingredientInfo.unit.abbreviation)")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(.ultraThinMaterial)
                                        .clipShape(.capsule)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                ingredients.remove(at: index)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Select ingredient")
                                    .font(.headline)
                                
                                VStack {
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
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .buttonBorderShape(.capsule)
                                    .disabled(quantityNeeded == 0.0)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 32))
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    Section {
                        if !stepInstructions.isEmpty {
                            Text("Steps")
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(.capsule)
                            
                            ForEach(Array(stepInstructions.indices), id: \.self) { index in
                                if editingStepIndex == index {
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .top) {
                                            TextEditor(text: $editedStepText)
                                                .textEditorStyle(.plain)
                                                .autocorrectionDisabled()
                                                .overlay(content: {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(.tertiary, lineWidth: 1)
                                                })
                                                .frame(minHeight: 32)
                                                .frame(maxHeight: 127)
                                            
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
                                                Image(systemName: "checkmark")
                                                    .font(.headline)
                                            }
                                            .buttonBorderShape(.circle)
                                            .buttonStyle(.borderedProminent)
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
                                            Text(editedStepImageData == nil ? "Add Photo" : "Update Photo")
                                        }
                                                     .tint(.blue)
                                                     .buttonStyle(.borderedProminent)
                                                     .buttonBorderShape(.capsule)
                                                     .task(id: stepImageItem) {
                                                         if let data = try? await stepImageItem?.loadTransferable(type: Data.self),
                                                            let uiImage = UIImage(data: data),
                                                            let compressedData = uiImage.resizedAndCompressed() {
                                                             withAnimation(.smooth) {
                                                                 editedStepImageData = compressedData
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
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 32))
                        }
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Insert step")
                                    .font(.headline)
                                
                                HStack(alignment: .top) {
                                    TextEditor(text: $newStep)
                                        .textEditorStyle(.plain)
                                        .autocorrectionDisabled()
                                        .overlay(content: {
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(.tertiary, lineWidth: 1)
                                        })
                                        .frame(minHeight: 32)
                                        .frame(maxHeight: 127)

                                    Button {
                                        guard !newStep.isEmpty else { return }

                                        stepInstructions.append(newStep)
                                        stepImages.append(stepImageData)

                                        newStep = ""
                                        stepImageData = nil
                                        stepImageItem = nil
                                    } label: {
                                        Image(systemName: "arrow.up")
                                            .font(.headline)
                                    }
                                    .buttonBorderShape(.circle)
                                    .buttonStyle(.borderedProminent)
                                    .disabled(newStep.isEmpty)
                                }

                                if let imageData = stepImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .clipShape(.rect(cornerRadius: 12))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }

                                PhotosPicker(selection: $stepImageItem,
                                             matching: .images,
                                             photoLibrary: .shared()) {
                                    Text(stepImageData == nil ? "Add Photo" : "Update Photo")
                                        .font(.headline)
                                    }
                                             .tint(.blue)
                                             .buttonStyle(.borderedProminent)
                                             .buttonBorderShape(.capsule)
                                             .task(id: stepImageItem) {
                                                 if let data = try? await stepImageItem?.loadTransferable(type: Data.self),
                                                    let uiImage = UIImage(data: data),
                                                    let compressedData = uiImage.resizedAndCompressed() {
                                                     withAnimation {
                                                         stepImageData = compressedData
                                                     }
                                                 }
                                             }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.rect(cornerRadius: 32))
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .background {
                    VStack (spacing: 0) {
                        if let imageData, let _ = UIImage(data: imageData) {
                            listBackgroundColor
                                .ignoresSafeArea()
                        } else {
                            LinearGradient(colors: [.purple, .primary], startPoint: .topLeading, endPoint: .bottom)
                                .ignoresSafeArea()
                        }
                    }
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $imageItem, matching: .images, photoLibrary: .shared())
                .onChange(of: imageData) { _, newData in
                    if let newData, let uiImage = UIImage(data: newData), let avgColor = uiImage.averageColor() {
                        listBackgroundColor = Color(avgColor)
                    } else {
                        listBackgroundColor = Color(.systemBackground)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            saveRecipe()
                        } label: {
                            Text("Save")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .foregroundStyle(.primary)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        .disabled(name.isEmpty || imageData == nil)
                    }
                }
            }
        }
        .onAppear {
            if let recipe = recipe {
                name = recipe.name
                descriptionRecipe = recipe.descriptionRecipe
                imageData = recipe.image
                duration = recipe.duration
                ingredients = recipe.ingredients ?? []
                stepInstructions = recipe.stepInstructions
                stepImages = recipe.stepImages
            }
            
            selectedFood = foods.first
            
            if let imageData, let uiImage = UIImage(data: imageData), let avgColor = uiImage.averageColor() {
                listBackgroundColor = Color(avgColor)
            }
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
    }
    
    func saveRecipe() {
        guard !name.isEmpty && imageData != nil else { return }
        
        if let recipe = recipe {
            // Update existing recipe
            recipe.name = name
            recipe.descriptionRecipe = descriptionRecipe
            recipe.image = imageData
            recipe.ingredients = ingredients
            recipe.stepInstructions = stepInstructions
            recipe.stepImages = stepImages
            recipe.duration = duration
        } else {
            // Create new recipe
            let newRecipe = RecipeModel(
                name: name,
                descriptionRecipe: descriptionRecipe,
                image: imageData,
                ingredients: ingredients,
                stepInstructions: stepInstructions,
                stepImages: stepImages,
                duration: duration
            )
            
            modelContext.insert(newRecipe)
        }
        
        dismiss()
    }
}

#Preview {
    EditRecipeView()
}
