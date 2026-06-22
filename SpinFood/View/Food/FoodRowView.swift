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
        HStack(spacing: 12) {
            Text(displayEmoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(stockColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(food.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))

                StockBar(percentage: food.stockPercentage, color: stockColor)
                    .frame(height: 4)
            }

            Spacer()

            Text("\(food.currentQuantity.formatted()) \(food.unit.abbreviation)")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(stockColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

struct StockBar: View {
    let percentage: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * percentage)
            }
        }
    }
}
