import SwiftUI
import PhotosUI
import PencilKit

// MARK: - Block Editor Sheet

struct StepBlockEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    var block: StepBlock
    var ingredients: [RecipeFoodModel]
    var allSteps: [StepRecipe]

    @State private var textContent: String = ""
    @State private var listItems: [String] = []
    @State private var isCheckList: Bool = false
    @State private var newListItemText: String = ""
    @State private var drawingData: Data? = nil
    @State private var timerDuration: TimeInterval = 60
    @State private var timerLabel: String = ""
    @State private var selectedIngredients: [UUID: Double] = [:]
    @State private var imagePickerItem: PhotosPickerItem? = nil
    @State private var showCamera = false

    private var canSave: Bool {
        switch block.type {
        case .text:       return !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .bulletList: return !listItems.isEmpty
        case .image:      return block.imageData != nil
        case .drawing:    return true
        case .timer:      return timerDuration > 0
        case .ingredient: return !selectedIngredients.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch block.type {
                case .text:       textEditor
                case .bulletList: bulletListEditor
                case .image:      imageEditor
                case .drawing:    drawingEditor
                case .timer:      timerEditor
                case .ingredient: ingredientPicker
                }
            }
            .navigationTitle(blockTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save(); dismiss() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: loadFromBlock)
        .task(id: imagePickerItem) {
            guard let item = imagePickerItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let compressed = uiImage.resizedAndCompressed(maxDimension: 800, compressionQuality: 0.65) else { return }
            block.imageData = compressed
            imagePickerItem = nil
        }
    }

    // MARK: - Text editor

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $textContent)
                .font(.system(.body, design: .serif))
                .textEditorStyle(.plain)
                .padding()
            if textContent.isEmpty {
                Text("Describe this step...")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 24)
                    .padding(.leading, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Bullet list editor

    private var bulletListEditor: some View {
        List {
            Section {
                Picker("Style", selection: $isCheckList) {
                    Text("Bullets").tag(false)
                    Text("Checklist").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            ForEach(listItems.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    if isCheckList {
                        Image(systemName: "square")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                    } else {
                        Circle()
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 5, height: 5)
                    }
                    TextField("Item \(i + 1)", text: $listItems[i])
                        .font(.system(.body, design: .serif))
                }
                .listRowBackground(Color.clear)
            }
            .onDelete { listItems.remove(atOffsets: $0) }
            .onMove  { listItems.move(fromOffsets: $0, toOffset: $1) }

            HStack(spacing: 10) {
                if isCheckList {
                    Image(systemName: "square")
                        .foregroundStyle(Color.secondary.opacity(0.3))
                        .frame(width: 16)
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 5, height: 5)
                }
                TextField("Add item…", text: $newListItemText)
                    .font(.system(.body, design: .serif))
                    .onSubmit { commitNewListItem() }
                if !newListItemText.isEmpty {
                    Button(action: commitNewListItem) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .tint(.accentColor)
                }
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Image editor

    private var imageEditor: some View {
        VStack(spacing: 20) {
            if let data = block.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(4)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.07))
                    .frame(height: 200)
                    .overlay {
                        Label("Select an image", systemImage: "photo")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: $imagePickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("Library", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Button { showCamera = true } label: {
                    Label("Camera", systemImage: "camera").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 20)
        .sheet(isPresented: $showCamera) {
            CameraImagePicker { data in block.imageData = data }
        }
    }

    // MARK: - Drawing editor

    private var drawingEditor: some View {
        VStack(spacing: 0) {
            Text("Draw anything for this step")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
            DrawingCanvasView(drawingData: $drawingData, isEditing: true)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Timer editor

    private var timerEditor: some View {
        Form {
            Section("Label (optional)") {
                TextField("e.g. Simmer sauce, Rest dough", text: $timerLabel)
                    .font(.system(.body, design: .serif))
            }
            Section("Duration") {
                TimePickerView(duration: $timerDuration)
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Ingredient picker (multi-select with quantities)

    private var ingredientPicker: some View {
        List {
            ForEach(ingredients) { item in
                if let food = item.ingredient {
                    let id = item.id
                    let isSelected = selectedIngredients[id] != nil
                    let totalQty = NSDecimalNumber(decimal: item.quantityNeeded).doubleValue
                    let elsewhere = allocatedElsewhere(ingredientID: id)
                    let currentQty = selectedIngredients[id] ?? 0
                    let maxQty = max(0, totalQty - elsewhere + currentQty)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Text(food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.system(.body, design: .serif))
                                Text("\(item.quantityNeeded.formatted()) \(food.unit.abbreviation) total")
                                    .font(.system(.caption, design: .serif))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                if isSelected {
                                    selectedIngredients.removeValue(forKey: id)
                                } else {
                                    let defaultQty = min(max(stepSize(for: totalQty), 0), maxQty)
                                    selectedIngredients[id] = defaultQty
                                }
                            } label: {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                                    .font(.title3)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)

                        if isSelected {
                            HStack(spacing: 8) {
                                Stepper(
                                    value: Binding(
                                        get: { selectedIngredients[id] ?? 0 },
                                        set: { selectedIngredients[id] = min(max($0, 0), maxQty) }
                                    ),
                                    in: 0...max(maxQty, 0),
                                    step: stepSize(for: totalQty)
                                ) {
                                    HStack(spacing: 4) {
                                        Text(formatQty(selectedIngredients[id] ?? 0))
                                            .font(.system(.body, design: .serif).monospacedDigit())
                                            .frame(minWidth: 44, alignment: .trailing)
                                        Text(food.unit.abbreviation)
                                            .font(.system(.caption, design: .serif))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 6)
                            .padding(.bottom, elsewhere > 0 ? 2 : 4)

                            if elsewhere > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.caption2)
                                    Text("\(formatQty(elsewhere)) \(food.unit.abbreviation) allocated in other steps")
                                        .font(.system(.caption2, design: .serif))
                                }
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 6)
                            }
                        }
                    }
                    .listRowBackground(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helpers

    private var blockTitle: String {
        switch block.type {
        case .text:       return "Text"
        case .bulletList: return "Bullet List"
        case .image:      return "Image"
        case .drawing:    return "Drawing"
        case .timer:      return "Timer"
        case .ingredient: return "Ingredients"
        }
    }

    private func allocatedElsewhere(ingredientID: UUID) -> Double {
        let key = ingredientID.uuidString
        let allBlocks = allSteps.flatMap { $0.sortedBlocks }
        let ingredientBlocks = allBlocks.filter { $0.id != block.id && $0.type == .ingredient }
        let quantities = ingredientBlocks.compactMap { $0.ingredientStepQuantities[key] }
        return quantities.reduce(0, +)
    }

    private func stepSize(for total: Double) -> Double {
        if total <= 5 { return 0.5 }
        if total <= 20 { return 1.0 }
        return 5.0
    }

    func formatQty(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func loadFromBlock() {
        textContent   = block.textContent
        listItems     = block.listItems
        isCheckList   = block.isCheckList
        drawingData   = block.drawingData
        timerDuration = block.timerDuration > 0 ? block.timerDuration : 60
        timerLabel    = block.timerLabel
        var loaded: [UUID: Double] = [:]
        for id in block.linkedIngredientIDs {
            loaded[id] = block.ingredientStepQuantities[id.uuidString] ?? 0
        }
        selectedIngredients = loaded
    }

    private func save() {
        switch block.type {
        case .text:
            block.textContent = textContent
        case .bulletList:
            block.listItems   = listItems
            block.isCheckList = isCheckList
        case .image:
            break
        case .drawing:
            block.drawingData = drawingData
        case .timer:
            block.timerDuration = timerDuration
            block.timerLabel    = timerLabel
        case .ingredient:
            block.linkedIngredientIDs = Array(selectedIngredients.keys)
            var qtys: [String: Double] = [:]
            for (id, qty) in selectedIngredients { qtys[id.uuidString] = qty }
            block.ingredientStepQuantities = qtys
        }
    }

    private func commitNewListItem() {
        let trimmed = newListItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        listItems.append(trimmed)
        newListItemText = ""
    }
}

// MARK: - Drawing Canvas (PencilKit)

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    var isEditing: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.tool = PKInkingTool(.pen, color: .label, width: 2)
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.delegate = context.coordinator
        if let data = drawingData, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.isUserInteractionEnabled = isEditing
        if isEditing {
            DispatchQueue.main.async {
                guard let window = canvas.window else { return }
                let picker = PKToolPicker.shared(for: window)
                picker?.setVisible(true, forFirstResponder: canvas)
                picker?.addObserver(canvas)
                canvas.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingCanvasView
        init(_ parent: DrawingCanvasView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvas: PKCanvasView) {
            parent.drawingData = canvas.drawing.dataRepresentation()
        }
    }
}
