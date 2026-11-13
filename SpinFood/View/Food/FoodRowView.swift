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

                if food.isExpired && !food.isOutOfStock {
                    Text("Expired")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if !food.isOutOfStock, let days = food.daysUntilExpiry {
                    Text(days == 0 ? "Expires today" : "Exp. \(days)d")
                        .font(.caption2)
                        .foregroundStyle(food.isExpiringSoon ? .orange : .secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        // One element per food: name, then amount, stock and expiry in words ("Exp. 3d" isn't speakable).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: food.name))
        .accessibilityValue(Text(verbatim: spokenStatus))
    }

    private var spokenStatus: String {
        var parts = [String(localized: "\(food.currentQuantity.formatted()) \(food.unit.abbreviation)")]
        if food.isOutOfStock {
            parts.append(String(localized: "Out of stock"))
        } else if food.isLowStock {
            parts.append(String(localized: "Low stock"))
        }
        if food.isExpired && !food.isOutOfStock {
            parts.append(String(localized: "Expired"))
        } else if !food.isOutOfStock, let days = food.daysUntilExpiry {
            parts.append(SpokenText.expiry(daysLeft: days))
        }
        return parts.joined(separator: ", ")
    }
}
