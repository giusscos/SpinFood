import Foundation
import SwiftData

/// Food that got thrown away. Keeps its own copy of the name so the log outlives the pantry item.
@Model
final class FoodWasteModel {
    var id: UUID = UUID()
    var wastedAt: Date = Date.now
    var quantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var foodName: String = ""
    var foodEmoji: String = ""
    @Relationship var food: FoodModel?

    /// Same estimate as the other stats: 1 ml counts as 1 g and one piece as 100 g.
    var estimatedGrams: Double {
        NSDecimalNumber(decimal: unit.convertToGrams(quantity)).doubleValue
    }

    init(wastedAt: Date = .now, quantity: Decimal, food: FoodModel) {
        self.id = UUID()
        self.wastedAt = wastedAt
        self.quantity = quantity
        self.unit = food.unit
        self.foodName = food.name
        self.foodEmoji = food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
        self.food = food
    }
}

extension Array where Element == FoodWasteModel {
    func estimatedGrams(in interval: DateInterval) -> Double {
        filter { interval.contains($0.wastedAt) }.reduce(0) { $0 + $1.estimatedGrams }
    }
}

extension Double {
    /// A weight in grams, shown in kg from 1000 g up and formatted for the person's region.
    var wasteWeightText: String {
        let measurement = self >= 1000
            ? Measurement(value: self / 1000, unit: UnitMass.kilograms)
            : Measurement(value: self.rounded(), unit: UnitMass.grams)
        return measurement.formatted(.measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(0...1))
        ))
    }
}
