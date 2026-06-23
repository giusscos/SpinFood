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

    @State private var steps: [StepRecipe] = []

    @State private var showPhotoPicker: Bool = false
    @State private var servings: Int = 2

    @State private var showIngredientsSheet: Bool = false
    @State private var showStepsBook: Bool = false

    @State private var editingIngredientIndex: Int? = nil

    private var editingIngredient: RecipeFoodModel? {
        guard let idx = editingIngredientIndex, idx < ingredients.count else { return nil }
        return ingredients[idx]
    }

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

                        Picker(selection: $servings) {
                            ForEach(1...20, id: \.self) { n in
                                Text("\(n) \(n == 1 ? "serving" : "servings")").tag(n)
                            }
                        } label: {
                            Label("\(servings) \(servings == 1 ? "serving" : "servings")", systemImage: "person.2")
                        }
                        .pickerStyle(.menu)
                        .fixedSize()
                        .padding(.top, 4)
                    }
                    .padding()

                    divider

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Duration", systemImage: "clock")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TimePickerView(duration: $duration)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    divider

                    ingredientsSection

                    divider

                    stepsSection

                    Spacer(minLength: 40)
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .photosPicker(isPresented: $showPhotoPicker, selection: $imageItem, matching: .images, photoLibrary: .shared())
            .sheet(isPresented: $showIngredientsSheet, onDismiss: { editingIngredientIndex = nil }) {
                NavigationStack {
                    ScrollView {
                        EditRecipeIngredientView(
                            foods: foods,
                            ingredients: $ingredients,
                            editingIngredient: editingIngredient,
                            onEditDone: { editingIngredientIndex = nil }
                        )
                    }
                    .background(paperBackground.ignoresSafeArea())
                    .navigationTitle(editingIngredientIndex != nil ? "Edit Ingredient" : "Ingredients")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showIngredientsSheet = false }
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showStepsBook) {
                StepBookCurlView(
                    steps: steps,
                    ingredients: ingredients,
                    mode: .edit,
                    onDismiss: { showStepsBook = false },
                    onAddStep: { steps.append(StepRecipe(text: "")) },
                    onDeleteStep: { step in steps.removeAll { $0.id == step.id } },
                    onMoveSteps: { indexSet, dest in steps.move(fromOffsets: indexSet, toOffset: dest) }
                )
                .ignoresSafeArea()
            }
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

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Ingredients", systemImage: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !ingredients.isEmpty {
                    Text("\(ingredients.count) item\(ingredients.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(.capsule)
                }
                Button {
                    editingIngredientIndex = nil
                    showIngredientsSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .padding(.leading, 6)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if !ingredients.isEmpty {
                VStack(spacing: 0) {
                    ForEach(ingredients) { item in
                        if let food = item.ingredient {
                            HStack(spacing: 12) {
                                Text(food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji)
                                    .font(.system(size: 24))
                                Text(food.name)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.quantityNeeded, format: .number) \(food.unit.abbreviation)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Menu {
                                    Button("Edit", systemImage: "pencil") {
                                        editingIngredientIndex = ingredients.firstIndex(where: { $0.id == item.id })
                                        showIngredientsSheet = true
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        withAnimation { ingredients.removeAll { $0.id == item.id } }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)

                            if item.id != ingredients.last?.id {
                                Divider().padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Steps", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !steps.isEmpty {
                    Text("\(steps.count) step\(steps.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(.capsule)
                }
                Button {
                    showStepsBook = true
                } label: {
                    Image(systemName: steps.isEmpty ? "plus.circle.fill" : "book.pages")
                        .font(.title3)
                }
                .padding(.leading, 6)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if !steps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            StepPreviewCard(step: step, index: index + 1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                .padding(.bottom, 10)

                Button {
                    showStepsBook = true
                } label: {
                    Label("Edit Steps", systemImage: "book.pages")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
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
