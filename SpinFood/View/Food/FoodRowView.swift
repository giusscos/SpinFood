import SwiftUI

struct FoodRowView: View {
    var food: FoodModel

    private var stockColor: Color {
        if food.isOutOfStock { return .red }
        if food.isLowStock { return .orange }
        return .green
    }

    private var expiryLabel: String? {
        guard let days = food.daysUntilExpiry else { return nil }
        if days < 0 { return "Expired" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days)d"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: food.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(food.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let label = expiryLabel {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(food.isExpired ? .red : (food.isExpiringSoon ? .orange : .secondary))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(food.currentQuantity.formatted()) \(food.unit.abbreviation)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(stockColor)

                StockBar(percentage: food.stockPercentage, color: stockColor)
                    .frame(width: 60, height: 4)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch food.category {
        case .produce:   return .green
        case .dairy:     return .yellow
        case .meat:      return .red
        case .seafood:   return .blue
        case .grains:    return .orange
        case .pantry:    return .brown
        case .frozen:    return .cyan
        case .beverages: return .indigo
        case .snacks:    return .purple
        case .other:     return .gray
        }
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
