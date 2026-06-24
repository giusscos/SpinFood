import SwiftUI

struct FoodRowView: View {
    var food: FoodModel

    private var stockColor: Color {
        if food.isOutOfStock { return .red }
        if food.isLowStock { return .orange }
        return .green
    }

    private var displayEmoji: String {
        food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(displayEmoji)
                .font(.system(size: 28))

            Text(food.name)
                .font(.system(.body, design: .serif).weight(.semibold))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.currentQuantity.formatted()) \(food.unit.abbreviation)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(stockColor)

                if food.isOutOfStock {
                    Text("Out of stock")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.8))
                } else if food.isLowStock {
                    Text("Low stock")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.8))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}
