//
//  EditRecipeIngredientView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/07/25.
//

import SwiftUI

struct EditRecipeIngredientView: View {
    var foods: [FoodModel]
    @Binding var ingredients: [RecipeFoodModel]
    var editingIngredient: RecipeFoodModel? = nil
    var onEditDone: (() -> Void)? = nil

    @State private var selectedFood: FoodModel?
    @State private var quantity: Decimal = 1
    @State private var searchText = ""

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    /// Foods this recipe already uses, including ones picked from the catalog and not saved yet.
    private var usedFoods: [FoodModel] {
        ingredients.compactMap(\.ingredient)
    }

    private var pantryMatches: [FoodModel] {
        foods
            .filter { food in
                !usedFoods.contains { $0.id == food.id }
                    && (trimmedSearch.isEmpty || food.name.localizedStandardContains(trimmedSearch))
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var catalogMatches: [GroceryItem] {
        GroceryCatalog.all
            .filter { item in
                item.pantryFood(in: foods) == nil
                    && item.pantryFood(in: usedFoods) == nil
                    && (trimmedSearch.isEmpty || item.matches(search: trimmedSearch))
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var showsCustomRow: Bool {
        !trimmedSearch.isEmpty
            && GroceryCatalog.item(matching: trimmedSearch) == nil
            && !foods.contains { $0.name.localizedCaseInsensitiveCompare(trimmedSearch) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let food = selectedFood {
                amountContent(food: food)
            } else {
                pickerContent
            }
        }
        .padding()
        .onAppear {
            if let editing = editingIngredient {
                selectedFood = editing.ingredient
                quantity = editing.quantityNeeded
            }
        }
    }

    // MARK: - Choosing a food

    private var pickerContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search ingredients", text: $searchText)
                    .autocorrectionDisabled()
            }
            .padding(10)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))

            if !pantryMatches.isEmpty {
                pickerSection("In your kitchen") {
                    ForEach(pantryMatches) { food in
                        pickerRow(
                            emoji: food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji,
                            name: food.name
                        ) {
                            select(food)
                        }
                    }
                }
            }

            if showsCustomRow {
                pickerRow(emoji: "➕", name: String(localized: "Add \"\(trimmedSearch)\"")) {
                    select(FoodModel(name: trimmedSearch, quantity: 1, unit: .piece))
                }
            }

            if !catalogMatches.isEmpty {
                pickerSection("More ingredients") {
                    ForEach(catalogMatches) { item in
                        pickerRow(emoji: item.emoji, name: item.name) {
                            select(item.makeFood(quantity: item.packQuantity, currentQuantity: 0, expiryDate: nil))
                        }
                    }
                }
            }
        }
    }

    private func pickerSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            LazyVStack(spacing: 0) {
                content()
            }
        }
    }

    private func pickerRow(emoji: String, name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 22))
                    .frame(width: 32)
                Text(name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func select(_ food: FoodModel) {
        searchText = ""
        quantity = food.unit == .gram || food.unit == .milliliter ? 100 : 1
        selectedFood = food
    }

    // MARK: - Setting the amount

    private func amountContent(food: FoodModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(editingIngredient != nil ? "Edit Ingredient" : "Add Ingredient")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            foodCard(food: food)

            // A food that isn't saved yet can still take any unit; saved ones keep the pantry's.
            if food.modelContext == nil {
                HStack {
                    Text("Unit")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: Binding(get: { food.unit }, set: { food.unit = $0 })) {
                        ForEach(FoodUnit.allCases, id: \.self) { unit in
                            Text(unit.localizedName).tag(unit)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 12)
            }

            QuantityTickerPicker(value: $quantity, unit: food.unit)
                .padding(12)
                .background(.regularMaterial, in: .rect(cornerRadius: 12))

            Button {
                guard quantity > 0 else { return }
                withAnimation {
                    if let editing = editingIngredient {
                        editing.ingredient = food
                        editing.quantityNeeded = quantity
                        onEditDone?()
                    } else {
                        ingredients.append(RecipeFoodModel(ingredient: food, quantityNeeded: quantity))
                    }
                    selectedFood = nil
                }
                quantity = 1
            } label: {
                Text(editingIngredient != nil ? "Update" : "Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .tint(.accent)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(quantity <= 0)
        }
    }

    private func foodCard(food: FoodModel) -> some View {
        Button {
            withAnimation { selectedFood = nil }
        } label: {
            HStack(spacing: 14) {
                let displayEmoji = food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
                Text(displayEmoji)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(categoryColor(food.category).opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(food.category.localizedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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

}

struct QuantityTickerPicker: View {
    @Binding var value: Decimal
    let unit: FoodUnit
    var minValue: Decimal = 0
    var maxValue: Decimal = 9999

    var tickStep: Decimal {
        switch unit {
        case .gram, .milliliter, .piece:
            return 1
        case .kilogram, .liter:
            return Decimal(string: "0.1") ?? 1
        case .tablespoon, .teaspoon:
            return Decimal(string: "0.5") ?? 1
        case .cup:
            return Decimal(string: "0.25") ?? 1
        }
    }

    @State private var isTyping = false
    @State private var typedText = ""
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                // Tap the number to type it: the ruler is slow for amounts like 1000 g.
                if isTyping {
                    TextField("", text: $typedText)
                        .keyboardType(.decimalPad)
                        .focused($isFieldFocused)
                        .font(.system(.title, design: .rounded).weight(.black))
                        .multilineTextAlignment(.trailing)
                        .fixedSize()
                        .frame(minWidth: 60, alignment: .trailing)
                        .onAppear { isFieldFocused = true }
                        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
                            guard let field = note.object as? UITextField else { return }
                            field.clearButtonMode = .never
                            field.selectAll(nil)
                        }
                        .onChange(of: typedText) { _, text in
                            // Accepts the decimal comma from the keyboards of Foo's European languages.
                            if let typed = Decimal(string: text.replacingOccurrences(of: ",", with: ".")) {
                                value = min(maxValue, typed)
                            }
                        }
                        .onChange(of: isFieldFocused) { _, focused in
                            if !focused {
                                isTyping = false
                                value = max(minValue, min(maxValue, value))
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") { isFieldFocused = false }
                                    .fontWeight(.semibold)
                            }
                        }
                } else {
                    Button {
                        typedText = NSDecimalNumber(decimal: value).stringValue
                        isTyping = true
                    } label: {
                        Text(value, format: .number)
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.1), value: value)
                    }
                    .buttonStyle(.plain)
                }
                Text(unit.abbreviation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            TickRulerRepresentable(
                value: $value,
                minValue: minValue,
                maxValue: maxValue,
                tickStep: tickStep
            )
            .frame(height: 40)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.12),
                        .init(color: .black, location: 0.88),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
    }
}

// MARK: - UIViewRepresentable bridge

private struct TickRulerRepresentable: UIViewRepresentable {
    @Binding var value: Decimal
    let minValue: Decimal
    let maxValue: Decimal
    let tickStep: Decimal

    func makeCoordinator() -> Coordinator {
        Coordinator(binding: $value)
    }

    func makeUIView(context: Context) -> TickRulerUIView {
        let view = TickRulerUIView()
        view.value = value
        view.minValue = minValue
        view.maxValue = maxValue
        view.tickStep = tickStep
        view.onValueChanged = { [weak coord = context.coordinator] newValue in
            coord?.binding.wrappedValue = newValue
        }
        return view
    }

    func updateUIView(_ uiView: TickRulerUIView, context: Context) {
        context.coordinator.binding = $value
        uiView.minValue = minValue
        uiView.maxValue = maxValue
        uiView.tickStep = tickStep
        if uiView.value != value {
            uiView.value = value
            uiView.setNeedsDisplay()
        }
    }

    final class Coordinator {
        var binding: Binding<Decimal>
        init(binding: Binding<Decimal>) { self.binding = binding }
    }
}

// MARK: - UIKit ruler view

private final class TickRulerUIView: UIView {
    var value: Decimal = 0
    var minValue: Decimal = 0
    var maxValue: Decimal = 9999
    var tickStep: Decimal = 1
    var onValueChanged: ((Decimal) -> Void)?

    private let tickSpacing: CGFloat = 14
    private let feedback = UISelectionFeedbackGenerator()

    private var gestureStartValue: Decimal = 0
    private var previousIntTicks: Int = 0
    private var effectiveTranslation: CGFloat = 0

    // Inertia scrolling after drag release
    private var displayLink: CADisplayLink?
    private var inertiaVelocity: CGFloat = 0
    private var inertiaTotalOffset: CGFloat = 0
    private var inertiaBaseValue: Decimal = 0
    private var inertiaLastIntTicks: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
        feedback.prepare()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { stopInertia() }
    }

    private func startInertia(velocity: CGFloat) {
        stopInertia()
        guard abs(velocity) > 50 else {
            effectiveTranslation = 0
            setNeedsDisplay()
            return
        }
        inertiaVelocity = velocity
        inertiaTotalOffset = 0
        inertiaBaseValue = value
        inertiaLastIntTicks = 0
        effectiveTranslation = 0
        let proxy = InertiaProxy(self)
        let link = CADisplayLink(target: proxy, selector: #selector(InertiaProxy.step))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopInertia() {
        displayLink?.invalidate()
        displayLink = nil
    }

    fileprivate func inertiaStep(_ link: CADisplayLink) {
        let dt = CGFloat(min(link.targetTimestamp - link.timestamp, 1.0 / 30.0))
        inertiaVelocity *= pow(0.95, dt * 60)
        inertiaTotalOffset += inertiaVelocity * dt
        effectiveTranslation = inertiaTotalOffset

        let rawTicksFloat = -inertiaTotalOffset / tickSpacing
        let intTicks = Int(rawTicksFloat)
        let desiredValue = inertiaBaseValue + Decimal(intTicks) * tickStep
        let clampedValue = max(minValue, min(maxValue, desiredValue))

        if intTicks != inertiaLastIntTicks {
            inertiaLastIntTicks = intTicks
            if clampedValue != value {
                value = clampedValue
                feedback.selectionChanged()
                feedback.prepare()
                onValueChanged?(value)
            }
        }

        let atBoundary = (clampedValue <= minValue && inertiaVelocity > 0) ||
                         (clampedValue >= maxValue && inertiaVelocity < 0)

        setNeedsDisplay()

        if abs(inertiaVelocity) < 5.0 || atBoundary {
            stopInertia()
            effectiveTranslation = 0
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let centerX = rect.width / 2
        let halfTicks = Int(rect.width / tickSpacing / 2) + 2
        let offset = effectiveTranslation.truncatingRemainder(dividingBy: tickSpacing)
        // All ticks share a common baseline; only the top edge scales.
        let baseline = rect.height - 4

        // Pre-extract color components so each tick can linearly blend accent → base.
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        tintColor.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        UIColor.label.withAlphaComponent(0.3).getRed(&br, green: &bg, blue: &bb, alpha: &ba)

        ctx.setLineCap(.round)

        for i in -halfTicks...halfTicks {
            let x = centerX + CGFloat(i) * tickSpacing + offset
            guard x >= 0 && x <= rect.width else { continue }
            let d = abs(x - centerX)

            // t = 0 at center (full accent, tallest) → 1 at 2.5 ticks away (base style)
            let t = min(d / (tickSpacing * 2.5), 1.0)

            let tickH    = 28 + (8   - 28)  * t   // 28 → 8
            let lineWidth = 2 + (1.5 - 2)   * t   // 2  → 1.5
            let color = UIColor(red:   ar + (br - ar) * t,
                                green: ag + (bg - ag) * t,
                                blue:  ab + (bb - ab) * t,
                                alpha: aa + (ba - aa) * t)

            ctx.setLineWidth(lineWidth)
            ctx.setStrokeColor(color.cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: baseline - tickH))
            ctx.addLine(to: CGPoint(x: x, y: baseline))
            ctx.strokePath()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            stopInertia()
            feedback.prepare()
            gestureStartValue = value
            previousIntTicks = 0
            effectiveTranslation = 0

        case .changed:
            let raw = gesture.translation(in: self).x
            // Positive raw = drag right = decreasing value
            let rawTicksFloat = -raw / tickSpacing

            let intTicks = Int(rawTicksFloat)
            let desiredValue = gestureStartValue + Decimal(intTicks) * tickStep
            let clampedValue = max(minValue, min(maxValue, desiredValue))

            // Freeze ruler visually when pushing past a boundary
            let isClampedLow = clampedValue <= minValue && rawTicksFloat < 0
            let isClampedHigh = clampedValue >= maxValue && rawTicksFloat > 0

            if isClampedLow || isClampedHigh {
                let effectiveTicks = NSDecimalNumber(decimal: (clampedValue - gestureStartValue) / tickStep).doubleValue
                effectiveTranslation = CGFloat(-effectiveTicks * Double(tickSpacing))
            } else {
                effectiveTranslation = raw
            }

            // Update value and fire haptics at full-tick boundaries
            let tickDelta = intTicks - previousIntTicks
            if tickDelta != 0 {
                previousIntTicks = intTicks
                if clampedValue != value {
                    value = clampedValue
                    feedback.selectionChanged()
                    feedback.prepare()
                    onValueChanged?(value)
                }
            }

            setNeedsDisplay()

        case .ended:
            let velocity = gesture.velocity(in: self).x
            gestureStartValue = value
            previousIntTicks = 0
            startInertia(velocity: velocity)

        case .cancelled:
            stopInertia()
            gestureStartValue = value
            previousIntTicks = 0
            effectiveTranslation = 0
            setNeedsDisplay()

        default:
            break
        }
    }
}

// Weak proxy breaks the CADisplayLink ↔ TickRulerUIView retain cycle.
private final class InertiaProxy: NSObject {
    private weak var ruler: TickRulerUIView?
    init(_ ruler: TickRulerUIView) { self.ruler = ruler }
    @objc func step(_ link: CADisplayLink) { ruler?.inertiaStep(link) }
}

#Preview {
    EditRecipeIngredientView(
        foods: [FoodModel(name: "Carrots")],
        ingredients: .constant([])
    )
}
