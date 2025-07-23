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
    @State private var imageItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var selectedFood: FoodModel?
    @State private var quantityNeeded: Decimal = 0.0

    @State private var steps: [StepRecipe] = []
    @State private var newStep: StepRecipe = StepRecipe(text: "")
    @State private var stepImageItem: PhotosPickerItem?
    
    @State private var listBackgroundColor: Color = Color(.systemBackground)
    @State private var showPhotoPicker: Bool = false
    
    @State private var showDeleteConfirmation: Bool = false
    
    enum Field: Hashable {
        case name
        case recipeDescription
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let size = geometry.size
                
                List {
                    EditRecipePhotoView(imageItem: $imageItem, imageData: $imageData, showPhotoPicker: $showPhotoPicker, size: size)
                    
                    Section {
                        VStack (spacing: 16) {
                            TextField("Name", text: $name)
                                .autocorrectionDisabled()
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .recipeDescription
                                }

                            TextEditor(text: $descriptionRecipe)
                                .textEditorStyle(.plain)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .padding(.trailing, 26)
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.secondary.opacity(0.5), lineWidth: 1)
                                })
                                .clipShape(.rect(cornerRadius: 20))
                                .overlay(alignment: .topLeading, content: {
                                    if descriptionRecipe.isEmpty {
                                        Text("Add a description")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                    }
                                })
                                .frame(minHeight: 28, maxHeight: 256)
                                .focused($focusedField, equals: .recipeDescription)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = nil
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
                    
                    EditRecipeIngredientView(foods: foods, ingredients: $ingredients, selectedFood: $selectedFood, quantityNeeded: $quantityNeeded)
                    
                    EditStepRecipeView(steps: $steps, newStep: $newStep, stepImageItem: $stepImageItem)
                    
                    if let _ = recipe {
                        Section {
                            Button (role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete recipe")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                        .padding(.bottom, 48)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .photosPicker(isPresented: $showPhotoPicker, selection: $imageItem, matching: .images, photoLibrary: .shared())
                .listStyle(.plain)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbarBackgroundVisibility(.hidden, for: .bottomBar)
                .ignoresSafeArea(.container)
                .background {
                    VStack (spacing: 0) {
                        if let imageData, let _ = UIImage(data: imageData) {
                            listBackgroundColor
                                .ignoresSafeArea()
                        } else {
                            LinearGradient(colors: [.secondary, .primary], startPoint: .topLeading, endPoint: .bottom)
                                .ignoresSafeArea()
                        }
                    }
                }
                .onChange(of: imageData) { _, newData in
                    if let newData, let uiImage = UIImage(data: newData), let avgColor = uiImage.averageColor() {
                        listBackgroundColor = Color(avgColor)
                    } else {
                        listBackgroundColor = Color(.systemBackground)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .foregroundStyle(.primary)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                    }
                    
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
                    
                    ToolbarItem(placement: .keyboard) {
                        Button {
                            hideKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                        .tint(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
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
