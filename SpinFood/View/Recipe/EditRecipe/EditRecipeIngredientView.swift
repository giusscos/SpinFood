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
                Text(food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji)
                    .font(.system(size: 36))

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

}

private struct QuantityTickerPicker: View {
    @Binding var value: Decimal
    let unit: FoodUnit
    var minValue: Decimal = 0
    var maxValue: Decimal = 9999

    @State private var previousTicks: Int = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let tickSpacing: CGFloat = 14
    private let feedback = UISelectionFeedbackGenerator()

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
                    .font(.system(.title2, design: .monospaced).bold())
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.1), value: value)
                Text(unit.abbreviation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let centerX = size.width / 2
                        let halfTicks = Int(size.width / tickSpacing / 2) + 2
                        let offset = dragOffset.truncatingRemainder(dividingBy: tickSpacing)

                        for i in -halfTicks...halfTicks {
                            let x = centerX + CGFloat(i) * tickSpacing + offset
                            let d = abs(x - centerX)
                            let tickH: CGFloat
                            if d < tickSpacing * 0.5 {
                                tickH = 28
                            } else if d < tickSpacing * 1.5 {
                                tickH = 18
                            } else {
                                tickH = 10
                            }
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: (size.height - tickH) / 2))
                            path.addLine(to: CGPoint(x: x, y: (size.height + tickH) / 2))
                            ctx.stroke(
                                path,
                                with: .color(.primary.opacity(0.35)),
                                lineWidth: 1.5
                            )
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: 28)
            }
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .updating($dragOffset) { gesture, state, _ in
                        state = gesture.translation.width
                    }
                    .onChanged { gesture in
                        let ticks = Int(-gesture.translation.width / tickSpacing)
                        let delta = ticks - previousTicks
                        guard delta != 0 else { return }
                        previousTicks = ticks
                        let newValue = max(minValue, min(maxValue, value + Decimal(delta) * tickStep))
                        guard newValue != value else { return }
                        value = newValue
                        feedback.selectionChanged()
                    }
                    .onEnded { _ in
                        previousTicks = 0
                    }
            )
        }
    }
}

#Preview {
    EditRecipeIngredientView(
        foods: [FoodModel(name: "Carrots")],
        ingredients: .constant([])
    )
}
