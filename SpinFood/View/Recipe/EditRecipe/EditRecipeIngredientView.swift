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

    var body: some View {
        if !foods.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(editingIngredient != nil ? "Edit Ingredient" : "Add Ingredient")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let food = selectedFood {
                        foodCard(food: food)

                        QuantityTickerPicker(value: $quantity, unit: food.unit)
                            .padding(12)
                            .background(.regularMaterial, in: .rect(cornerRadius: 12))
                    }

                    Button {
                        guard let food = selectedFood, quantity > 0 else { return }
                        withAnimation {
                            if let editing = editingIngredient {
                                editing.ingredient = food
                                editing.quantityNeeded = quantity
                                onEditDone?()
                            } else {
                                ingredients.append(RecipeFoodModel(ingredient: food, quantityNeeded: quantity))
                            }
                        }
                        quantity = 1
                        selectedFood = foods.first
                    } label: {
                        Text(editingIngredient != nil ? "Update" : "Add")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.accent)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(selectedFood == nil || quantity <= 0)
                }
            }
            .padding()
            .onAppear {
                if let editing = editingIngredient {
                    selectedFood = editing.ingredient
                    quantity = editing.quantityNeeded
                } else if selectedFood == nil {
                    selectedFood = foods.first
                }
            }
        }
    }

    private func foodCard(food: FoodModel) -> some View {
        Menu {
            ForEach(foods) { f in
                Button {
                    selectedFood = f
                    quantity = 1
                } label: {
                    Text("\(f.emoji.isEmpty ? f.category.defaultEmoji : f.emoji) \(f.name)")
                }
            }
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
                    Text(food.category.rawValue)
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

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value, format: .number)
                    .font(.system(.title, design: .rounded).weight(.black))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.1), value: value)
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
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let centerX = rect.width / 2
        let halfTicks = Int(rect.width / tickSpacing / 2) + 2
        let offset = effectiveTranslation.truncatingRemainder(dividingBy: tickSpacing)

        ctx.setLineWidth(1.5)
        ctx.setLineCap(.round)

        for i in -halfTicks...halfTicks {
            let x = centerX + CGFloat(i) * tickSpacing + offset
            guard x >= 0 && x <= rect.width else { continue }
            let d = abs(x - centerX)
            let tickH: CGFloat = d < tickSpacing * 0.5 ? 28 : (d < tickSpacing * 1.5 ? 18 : 10)

            ctx.setStrokeColor(UIColor.label.withAlphaComponent(0.35).cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: (rect.height - tickH) / 2))
            ctx.addLine(to: CGPoint(x: x, y: (rect.height + tickH) / 2))
            ctx.strokePath()
        }

        // Fixed center accent marker
        ctx.setFillColor(tintColor.cgColor)
        ctx.fill(CGRect(x: centerX - 1, y: (rect.height - 28) / 2, width: 2, height: 28))
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
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
                    onValueChanged?(value)
                }
            }

            setNeedsDisplay()

        case .ended, .cancelled:
            gestureStartValue = value
            previousIntTicks = 0
            effectiveTranslation = 0
            setNeedsDisplay()

        default:
            break
        }
    }
}

#Preview {
    EditRecipeIngredientView(
        foods: [FoodModel(name: "Carrots")],
        ingredients: .constant([])
    )
}
