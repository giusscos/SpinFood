//
//  FoodRefillView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import SwiftUI

struct FoodRefillView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: [FoodModel]

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var body: some View {
        List {
            Section {
                ForEach(food) { value in
                    RefillFoodRowView(food: value)
                        .listRowBackground(paperBackground)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ready to refill?")
                    .font(.system(.title3, design: .serif).weight(.semibold))
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                refillAllFood()
            } label: {
                Label("Confirm Refill", systemImage: "bag.fill.badge.plus")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
        }
    }

    func refillAllFood() {
        for value in food {
            if value.currentQuantity < value.quantity {
                let refillAmount = value.quantity - value.currentQuantity

                let refill = FoodRefillModel(
                    refilledAt: Date.now,
                    quantity: refillAmount,
                    unit: value.unit,
                    food: value
                )

                modelContext.insert(refill)

                value.currentQuantity = value.quantity
            }
        }
        dismiss()
    }
}

struct RefillFoodRowView: View {
    let food: FoodModel

    private var refillAmount: Decimal {
        food.quantity - food.currentQuantity
    }

    private var fillRatio: CGFloat {
        guard food.quantity > 0 else { return 0 }
        return CGFloat(truncating: (food.currentQuantity / food.quantity) as NSDecimalNumber)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(food.name)
                    .font(.system(.headline, design: .rounded))

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("+\(refillAmount.formatted())")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text(food.unit.abbreviation)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(Color.accentColor.opacity(0.75))
                        .frame(width: geo.size.width * fillRatio)
                }
            }
            .frame(height: 5)

            HStack(spacing: 4) {
                Text(food.currentQuantity, format: .number)
                Text(food.unit.abbreviation)
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .imageScale(.small)
                Text(food.quantity, format: .number)
                    .fontWeight(.medium)
                Text(food.unit.abbreviation)
                    .foregroundStyle(.secondary)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FoodRefillView(food: [])
    }
}
