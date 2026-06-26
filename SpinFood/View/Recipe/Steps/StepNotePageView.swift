import SwiftUI
import PhotosUI
import PencilKit

// MARK: - Step Notebook Page

struct StepNotePageView: View {
    @Environment(\.modelContext) private var modelContext

    var step: StepRecipe
    var stepNumber: Int
    var totalSteps: Int
    var ingredients: [RecipeFoodModel]
    var allSteps: [StepRecipe]
    var isEditing: Bool
    var isCooking: Bool
    var onBack: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @State private var editingBlock: StepBlock? = nil
    @State private var showImagePicker = false
    @State private var pickedImageItem: PhotosPickerItem? = nil
    @State private var pendingImageBlock: StepBlock? = nil

    private var sortedBlocks: [StepBlock] { step.sortedBlocks }

    private let paperColor = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    })

    var body: some View {
        ZStack {
            DottedPaperBackground().ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    stepHeader

                    Rectangle()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    if sortedBlocks.isEmpty {
                        legacyOrEmptyContent
                    } else {
                        blocksContent
                    }

                    if isEditing {
                        addBlockToolbar
                            .padding(.top, 20)
                            .padding(.horizontal, 24)
                    }

                    Spacer(minLength: 80)
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            pageToolbar
        }
        .sheet(item: $editingBlock) { block in
            StepBlockEditorSheet(block: block, ingredients: ingredients, allSteps: allSteps)
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $pickedImageItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .task(id: pickedImageItem) {
            guard let item = pickedImageItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let compressed = uiImage.resizedAndCompressed(maxDimension: 800, compressionQuality: 0.65) else { return }
            pendingImageBlock?.imageData = compressed
            pickedImageItem = nil
            pendingImageBlock = nil
        }
    }

    // MARK: - Page toolbar (replaces NavigationStack toolbar)

    private var pageToolbar: some View {
        HStack(spacing: 0) {
            // Leading
            Group {
                if isEditing {
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Steps")
                                .font(.system(.subheadline, design: .serif))
                        }
                    }
                } else if isCooking {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                    }
                } else {
                    Color.clear
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            if isCooking {
                Text("\(stepNumber) / \(totalSteps)")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Trailing
            Group {
                if isEditing {
                    Menu {
                        Button("Delete Step", systemImage: "trash", role: .destructive) {
                            onBack?()
                            onDelete?()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                    }
                } else {
                    Color.clear
                }
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(paperColor)
    }

    // MARK: - Header

    private var stepHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("STEP")
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(.secondary)
                .tracking(2)
                .padding(.bottom, 2)
            Text("\(stepNumber)")
                .font(.system(size: 38, weight: .bold, design: .serif))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Legacy / empty

    @ViewBuilder
    private var legacyOrEmptyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let data = step.image, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(4)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            if !step.text.isEmpty {
                Text(step.text)
                    .font(.system(.body, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if step.text.isEmpty && step.image == nil && isEditing {
                Text("Tap a block below to add content")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(.tertiary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Blocks

    private var blocksContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(sortedBlocks) { block in
                blockRow(block)
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func blockRow(_ block: StepBlock) -> some View {
        HStack(alignment: .top, spacing: 8) {
            blockContentView(block)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isEditing {
                Menu {
                    Button("Edit", systemImage: "pencil") { editingBlock = block }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        withAnimation { deleteBlock(block) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.secondary.opacity(0.1), in: .circle)
                }
            }
        }
    }

    @ViewBuilder
    private func blockContentView(_ block: StepBlock) -> some View {
        switch block.type {
        case .text:
            Text(block.textContent.isEmpty ? "..." : block.textContent)
                .font(.system(.body, design: .serif))
                .foregroundStyle(block.textContent.isEmpty ? .tertiary : .primary)
                .fixedSize(horizontal: false, vertical: true)

        case .bulletList:
            if block.listItems.isEmpty {
                Text("Empty list")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.tertiary)
                    .italic()
            } else if block.isCheckList && isCooking {
                CheckListBlockView(items: block.listItems)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(block.listItems.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            if block.isCheckList {
                                Image(systemName: "square")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 16)
                                    .padding(.top, 2)
                            } else {
                                Circle()
                                    .fill(Color.secondary.opacity(0.5))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 8)
                            }
                            Text(item)
                                .font(.system(.body, design: .serif))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

        case .image:
            if let data = block.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(4)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 120)
                    .overlay {
                        Label("No image", systemImage: "photo")
                            .foregroundStyle(.tertiary)
                            .font(.callout)
                    }
            }

        case .drawing:
            if let data = block.drawingData,
               let drawing = try? PKDrawing(data: data),
               !drawing.bounds.isEmpty {
                let bounds = drawing.bounds.insetBy(dx: -12, dy: -12)
                let img = drawing.image(from: bounds, scale: UIScreen.main.scale)
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.6))
                    .clipShape(.rect(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.07))
                    .frame(height: 80)
                    .overlay {
                        Label("Empty drawing", systemImage: "pencil.tip")
                            .foregroundStyle(.tertiary)
                            .font(.callout)
                    }
            }

        case .timer:
            if isCooking {
                StepTimerBlockView(duration: block.timerDuration, label: block.timerLabel)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "timer").foregroundStyle(.orange)
                    Text(block.timerLabel.isEmpty ? "Timer" : block.timerLabel)
                        .font(.system(.callout, design: .serif).weight(.medium))
                    Spacer()
                    Text(timerDisplayString(block.timerDuration))
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.07), in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.15), lineWidth: 1))
            }

        case .ingredient:
            if block.linkedIngredientIDs.isEmpty {
                Text("No ingredients selected")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(.tertiary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(block.linkedIngredientIDs, id: \.self) { id in
                        if let item = ingredients.first(where: { $0.id == id }),
                           let food = item.ingredient {
                            let qty = block.ingredientStepQuantities[id.uuidString]
                                ?? NSDecimalNumber(decimal: item.quantityNeeded).doubleValue
                            HStack(spacing: 10) {
                                Text(food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.system(.callout, design: .serif).weight(.medium))
                                    Text("\(formatQty(qty)) \(food.unit.abbreviation)")
                                        .font(.system(.caption, design: .serif))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.06), in: .rect(cornerRadius: 10))
            }
        }
    }

    // MARK: - Add block toolbar

    private var addBlockToolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.secondary.opacity(0.12))
                .frame(height: 1)
            Text("ADD CONTENT")
                .font(.system(size: 9, weight: .semibold, design: .serif))
                .foregroundStyle(.secondary)
                .tracking(2)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 10
            ) {
                StepAddBlockButton(icon: "text.alignleft", label: "Text")    { addBlock(.text) }
                StepAddBlockButton(icon: "list.bullet",   label: "List")     { addBlock(.bulletList) }
                StepAddBlockButton(icon: "photo",         label: "Photo")    { addImageBlock() }
                StepAddBlockButton(icon: "pencil.tip",    label: "Draw")     { addDrawingBlock() }
                StepAddBlockButton(icon: "timer",         label: "Timer")    { addBlock(.timer) }
                if !ingredients.isEmpty {
                    StepAddBlockButton(icon: "fork.knife", label: "Ingredient") { addIngredientBlock() }
                }
            }
        }
    }

    // MARK: - Block mutations

    private func addBlock(_ type: StepBlockType) {
        let block = StepBlock(type: type, order: sortedBlocks.count)
        appendBlock(block)
        editingBlock = block
    }

    private func addImageBlock() {
        let block = StepBlock(type: .image, order: sortedBlocks.count)
        appendBlock(block)
        pendingImageBlock = block
        showImagePicker = true
    }

    private func addDrawingBlock() {
        let block = StepBlock(type: .drawing, order: sortedBlocks.count)
        appendBlock(block)
        editingBlock = block
    }

    private func addIngredientBlock() {
        let block = StepBlock(type: .ingredient, order: sortedBlocks.count)
        appendBlock(block)
        editingBlock = block
    }

    private func appendBlock(_ block: StepBlock) {
        if step.blocks == nil { step.blocks = [] }
        step.blocks!.append(block)
        modelContext.insert(block)
    }

    private func deleteBlock(_ block: StepBlock) {
        step.blocks?.removeAll { $0.id == block.id }
        for (i, b) in sortedBlocks.enumerated() { b.order = i }
    }

    private func timerDisplayString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = Int(t) % 3600 / 60, s = Int(t) % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 && s > 0 { return "\(m)m \(s)s" }
        if m > 0 { return "\(m) min" }
        return "\(s)s"
    }

    private func formatQty(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

// MARK: - Interactive checklist (cook mode)

private struct CheckListBlockView: View {
    let items: [String]
    @State private var checked: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                Button {
                    if checked.contains(i) { checked.remove(i) } else { checked.insert(i) }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: checked.contains(i) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(checked.contains(i) ? Color.accentColor : Color.secondary)
                            .frame(width: 16)
                            .padding(.top, 2)
                        Text(items[i])
                            .font(.system(.body, design: .serif))
                            .strikethrough(checked.contains(i), color: .secondary)
                            .foregroundStyle(checked.contains(i) ? .secondary : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

// MARK: - Dotted paper background

struct DottedPaperBackground: View {
    var body: some View {
        ZStack {
            Color(UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? .systemBackground
                    : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
            })
            Canvas { ctx, size in
                let spacing: CGFloat = 22
                let r: CGFloat = 0.85
                let shade = GraphicsContext.Shading.color(Color.secondary.opacity(0.2))
                var row = spacing
                while row < size.height {
                    var col = spacing
                    while col < size.width {
                        ctx.fill(Path(ellipseIn: CGRect(x: col - r, y: row - r, width: r * 2, height: r * 2)), with: shade)
                        col += spacing
                    }
                    row += spacing
                }
            }
        }
    }
}

// MARK: - Add block button

struct StepAddBlockButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.system(size: 10, design: .serif))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.07), in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
    }
}

// MARK: - Timer block (interactive, used in cook mode)

struct StepTimerBlockView: View {
    var duration: TimeInterval
    var label: String

    @State private var remaining: TimeInterval = 0
    @State private var isRunning = false
    @State private var timerRef: Timer? = nil

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "timer").foregroundStyle(.orange)
                Text(label.isEmpty ? "Timer" : label)
                    .font(.system(.callout, design: .serif).weight(.semibold))
                Spacer()
                Text(timeString(remaining))
                    .font(.system(.title2, design: .serif).monospacedDigit().weight(.semibold))
                    .foregroundStyle(remaining <= 30 && isRunning ? .red : .primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: remaining)
            }
            HStack(spacing: 10) {
                Button(action: toggleTimer) {
                    Label(
                        isRunning ? "Pause" : (remaining < duration && remaining > 0 ? "Resume" : "Start"),
                        systemImage: isRunning ? "pause.fill" : "play.fill"
                    )
                    .font(.system(.callout, design: .serif).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button(action: resetTimer) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .disabled(remaining == duration && !isRunning)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.07), in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.18), lineWidth: 1))
        .onAppear { remaining = duration }
        .onDisappear { stopTimer() }
    }

    private func toggleTimer() { isRunning ? stopTimer() : startTimer() }

    private func startTimer() {
        guard remaining > 0 else { return }
        isRunning = true
        timerRef = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 { remaining -= 1 } else { stopTimer() }
        }
    }

    private func stopTimer() {
        isRunning = false; timerRef?.invalidate(); timerRef = nil
    }

    private func resetTimer() { stopTimer(); remaining = duration }

    private func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = Int(t) % 3600 / 60, s = Int(t) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
