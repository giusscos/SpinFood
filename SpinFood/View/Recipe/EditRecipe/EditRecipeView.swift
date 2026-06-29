//
//  EditRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var imageToCrop: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageToCrop = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CropImageView: View {
    @Environment(\.dismiss) var dismiss

    let image: UIImage
    let onCrop: (Data?) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = .zero

    private var cropSize: CGFloat {
        min(containerSize.width, containerSize.height) - 48
    }

    // Minimum scale so the image always fully covers the crop square.
    private var minScale: CGFloat {
        guard containerSize.width > 0 else { return 1.0 }
        let fitScale = min(containerSize.width / image.size.width,
                           containerSize.height / image.size.height)
        let dw = image.size.width * fitScale
        let dh = image.size.height * fitScale
        return max(1.0, max(cropSize / dw, cropSize / dh))
    }

    // Clamp offset so image edges never enter the crop square.
    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let fitScale = min(containerSize.width / image.size.width,
                           containerSize.height / image.size.height)
        let dw = image.size.width * fitScale * scale
        let dh = image.size.height * fitScale * scale
        let maxX = max(0, (dw - cropSize) / 2)
        let maxY = max(0, (dh - cropSize) / 2)
        return CGSize(
            width:  min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black

                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let delta = value / lastScale
                                            lastScale = value
                                            scale = max(minScale, scale * delta)
                                            offset = clampedOffset(offset)
                                        }
                                        .onEnded { _ in
                                            lastScale = 1.0
                                            offset = clampedOffset(offset)
                                            lastOffset = offset
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            let proposed = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            offset = clampedOffset(proposed)
                                        }
                                        .onEnded { _ in lastOffset = offset }
                                )
                            )

                        // Dimming overlay with cutout
                        Rectangle()
                            .fill(.black.opacity(0.55))
                            .overlay {
                                Rectangle()
                                    .frame(width: cropSize, height: cropSize)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                            .allowsHitTesting(false)

                        // Crop border + corners
                        Canvas { ctx, size in
                            let w = cropSize
                            let h = cropSize
                            let ox = (size.width - w) / 2
                            let oy = (size.height - h) / 2
                            let corner: CGFloat = 22

                            var border = Path()
                            border.addRect(CGRect(x: ox, y: oy, width: w, height: h))
                            ctx.stroke(border, with: .color(.white.opacity(0.7)), lineWidth: 1)

                            var c = Path()
                            c.move(to: CGPoint(x: ox + corner, y: oy))
                            c.addLine(to: CGPoint(x: ox, y: oy))
                            c.addLine(to: CGPoint(x: ox, y: oy + corner))
                            c.move(to: CGPoint(x: ox + w - corner, y: oy))
                            c.addLine(to: CGPoint(x: ox + w, y: oy))
                            c.addLine(to: CGPoint(x: ox + w, y: oy + corner))
                            c.move(to: CGPoint(x: ox, y: oy + h - corner))
                            c.addLine(to: CGPoint(x: ox, y: oy + h))
                            c.addLine(to: CGPoint(x: ox + corner, y: oy + h))
                            c.move(to: CGPoint(x: ox + w - corner, y: oy + h))
                            c.addLine(to: CGPoint(x: ox + w, y: oy + h))
                            c.addLine(to: CGPoint(x: ox + w, y: oy + h - corner))
                            ctx.stroke(c, with: .color(.white), lineWidth: 3)
                        }
                        .allowsHitTesting(false)
                    }
                    .onAppear {
                        let cs = geo.size
                        containerSize = cs
                        // Compute initial minScale from geo.size directly
                        let fitScale = min(cs.width / image.size.width,
                                           cs.height / image.size.height)
                        let dw = image.size.width * fitScale
                        let dh = image.size.height * fitScale
                        let crop = min(cs.width, cs.height) - 48
                        scale = max(1.0, max(crop / dw, crop / dh))
                    }
                    .onChange(of: geo.size) { _, size in containerSize = size }
                }
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Crop Photo")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { performCrop() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func performCrop() {
        let size = CGSize(width: cropSize, height: cropSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        let cropped = renderer.image { _ in
            let fitScale = min(containerSize.width / image.size.width,
                               containerSize.height / image.size.height)
            let totalScale = fitScale * scale
            let dw = image.size.width * totalScale
            let dh = image.size.height * totalScale
            let cx = containerSize.width / 2 + offset.width
            let cy = containerSize.height / 2 + offset.height
            let cropLeft = (containerSize.width - cropSize) / 2
            let cropTop  = (containerSize.height - cropSize) / 2
            let drawX = cx - dw / 2 - cropLeft
            let drawY = cy - dh / 2 - cropTop
            image.draw(in: CGRect(x: drawX, y: drawY, width: dw, height: dh))
        }
        onCrop(cropped.resizedAndCompressed())
        dismiss()
    }
}

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
    @State private var showCamera: Bool = false
    @State private var imageToCrop: UIImage? = nil
    @State private var originalImage: UIImage? = nil
    @State private var cropSource: UIImage? = nil
    @State private var showCrop: Bool = false
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
        !name.isEmpty && !steps.isEmpty
    }

    private func categoryColor(_ category: FoodCategory) -> Color {
        switch category {
        case .produce: return .green
        case .dairy: return .yellow
        case .meat: return .red
        case .seafood: return .blue
        case .grains: return .orange
        case .pantry: return .brown
        case .frozen: return .cyan
        case .beverages: return .indigo
        case .snacks: return .purple
        case .other: return .gray
        }
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
                        showPhotoPicker: $showPhotoPicker,
                        showCamera: $showCamera,
                        hasOriginalImage: originalImage != nil,
                        onRecrop: startRecrop
                    )
                    .padding(.top, 32)
                    .padding(.bottom, 16)

                    // Title & description
                    VStack(alignment: .leading, spacing: 24) {
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

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Serves", systemImage: "person.3.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            Picker(selection: $servings) {
                                ForEach(1...20, id: \.self) { n in
                                    Text("\(n) \(n == 1 ? "serving" : "servings")").tag(n)
                                }
                            } label: {
                                Label("\(servings) \(servings == 1 ? "serving" : "servings")", systemImage: "person.2")
                            }
                            .pickerStyle(.menu)
                        }
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
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(imageToCrop: $imageToCrop)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showCrop) {
                if let src = cropSource {
                    CropImageView(image: src) { data in
                        withAnimation(.smooth) { imageData = data }
                        imageToCrop = nil
                        cropSource = nil
                    }
                }
            }
            .onChange(of: imageToCrop) { _, newImage in
                if let img = newImage {
                    originalImage = img
                    cropSource = img
                    showCrop = true
                }
            }
            .onChange(of: imageData) { _, newData in
                if newData == nil { originalImage = nil }
            }
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
                    if let data = recipe.image, let uiImage = UIImage(data: data) {
                        originalImage = uiImage
                    }
                    duration = recipe.duration
                    servings = recipe.servings
                    ingredients = recipe.ingredients ?? []
                    steps = recipe.steps ?? []
                }
            }
            .task(id: imageItem) {
                if let data = try? await imageItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    imageToCrop = uiImage
                }
            }
        }
    }

    private func startRecrop() {
        guard let original = originalImage else { return }
        cropSource = original
        showCrop = true
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
                VStack(spacing: 8) {
                    ForEach(ingredients) { item in
                        if let food = item.ingredient {
                            HStack(spacing: 12) {
                                let displayEmoji = food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
                                Text(displayEmoji)
                                    .font(.system(size: 22))
                                    .frame(width: 40, height: 40)
                                    .background(categoryColor(food.category).opacity(0.15))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    Text("\(item.quantityNeeded, format: .number) \(food.unit.abbreviation)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: .rect(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
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
