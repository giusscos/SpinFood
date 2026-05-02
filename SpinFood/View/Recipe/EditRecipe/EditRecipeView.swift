//
//  EditRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

extension UIImage {
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

enum EditRecipeField: Hashable {
    case name
    case recipeDescription
    case step
}

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query var foods: [FoodModel]

    var recipe: RecipeModel?
    var onDelete: () -> Void = {}

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
    @State private var servings: Int = 2

    @FocusState private var focusedField: EditRecipeField?

    var canSaveRecipe: Bool {
        !name.isEmpty && !ingredients.isEmpty && !steps.isEmpty
    }

    private var paperBackground: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Polaroid photo
                    EditRecipePhotoView(
                        imageItem: $imageItem,
                        imageData: $imageData,
                        showPhotoPicker: $showPhotoPicker
                    )
                    .padding(.top, 32)
                    .padding(.bottom, 16)

                    // Title & description
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Recipe name", text: $name)
                            .autocorrectionDisabled()
                            .font(.largeTitle.bold())
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .recipeDescription }

                        TextEditor(text: $descriptionRecipe)
                            .textEditorStyle(.plain)
                            .autocorrectionDisabled()
                            .offset(x: -6)
                            .padding(.vertical, 4)
                            .overlay(alignment: .topLeading) {
                                if descriptionRecipe.isEmpty {
                                    Text("Add a description")
                                        .foregroundColor(.secondary)
                                        .offset(x: -2)
                                        .padding(.vertical, 12)
                                }
                            }
                            .frame(minHeight: 60, maxHeight: 200)
                            .focused($focusedField, equals: .recipeDescription)
                            .onSubmit { focusedField = nil }
                    }
                    .padding()

                    divider

                    // Duration & Servings
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Duration", systemImage: "clock")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            TimePickerView(duration: $duration)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Servings", systemImage: "person.2")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Stepper("\(servings) \(servings == 1 ? "serving" : "servings")", value: $servings, in: 1...20)
                                .labelsHidden()

                            Text("\(servings) \(servings == 1 ? "serving" : "servings")")
                                .font(.callout.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()

                    divider

                    EditRecipeIngredientView(
                        foods: foods,
                        ingredients: $ingredients,
                        selectedFood: $selectedFood,
                        quantityNeeded: $quantityNeeded
                    )

                    divider

                    EditStepRecipeView(
                        steps: $steps,
                        newStep: $newStep,
                        stepImageItem: $stepImageItem
                    )

                    Spacer(minLength: 40)
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .photosPicker(isPresented: $showPhotoPicker, selection: $imageItem, matching: .images, photoLibrary: .shared())
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26, *) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    } else {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .gray)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            saveRecipe()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(!canSaveRecipe)
                    } else {
                        Button {
                            saveRecipe()
                        } label: {
                            Label("Save", systemImage: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, !canSaveRecipe ? .gray : .accent)
                        }
                        .disabled(!canSaveRecipe)
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
            .onAppear {
                if let recipe {
                    name = recipe.name
                    descriptionRecipe = recipe.descriptionRecipe
                    imageData = recipe.image
                    duration = recipe.duration
                    servings = recipe.servings
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
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal)
    }

    func saveRecipe() {
        if !canSaveRecipe { return }

        if let recipe {
            recipe.name = name
            recipe.descriptionRecipe = descriptionRecipe
            recipe.image = imageData
            recipe.ingredients = ingredients
            recipe.duration = duration
            recipe.servings = servings
            recipe.steps = steps
        } else {
            let newRecipe = RecipeModel(
                name: name,
                descriptionRecipe: descriptionRecipe,
                image: imageData,
                duration: duration,
                servings: servings,
                ingredients: ingredients,
                steps: steps
            )
            modelContext.insert(newRecipe)
        }

        dismiss()
    }

#if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif
}

#Preview {
    EditRecipeView()
}
