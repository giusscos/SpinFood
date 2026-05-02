import Foundation
import SwiftData

enum FoodCategory: String, CaseIterable, Codable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case seafood = "Seafood"
    case grains = "Grains"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case other = "Other"

    var icon: String {
        switch self {
        case .produce:    return "leaf.fill"
        case .dairy:      return "cup.and.saucer.fill"
        case .meat:       return "flame.fill"
        case .seafood:    return "fish.fill"
        case .grains:     return "wind"
        case .pantry:     return "cabinet.fill"
        case .frozen:     return "snowflake"
        case .beverages:  return "drop.fill"
        case .snacks:     return "popcorn.fill"
        case .other:      return "archivebox.fill"
        }
    }

    var color: String {
        switch self {
        case .produce:    return "green"
        case .dairy:      return "yellow"
        case .meat:       return "red"
        case .seafood:    return "blue"
        case .grains:     return "orange"
        case .pantry:     return "brown"
        case .frozen:     return "cyan"
        case .beverages:  return "indigo"
        case .snacks:     return "purple"
        case .other:      return "gray"
        }
    }
}

@Model
final class FoodModel {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Decimal = 0.0
    var currentQuantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var category: FoodCategory = FoodCategory.other
    var expiryDate: Date? = nil
    var createdAt: Date = Date.now
    var rating: Int = 0

    @Relationship(inverse: \RecipeFoodModel.ingredient) var recipes: [RecipeFoodModel]? = []
    @Relationship(deleteRule: .cascade, inverse: \FoodConsumptionModel.food) var consumptions: [FoodConsumptionModel]? = []
    @Relationship(deleteRule: .cascade, inverse: \FoodRefillModel.food) var refills: [FoodRefillModel]? = []

    var stockPercentage: Double {
        guard quantity > 0 else { return 0 }
        return Double(truncating: (currentQuantity / quantity) as NSDecimalNumber).clamped(to: 0...1)
    }

    var isLowStock: Bool { stockPercentage < 0.2 && stockPercentage > 0 }
    var isOutOfStock: Bool { currentQuantity <= 0 }

    var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: expiry).day
    }

    var isExpiringSoon: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days <= 3 && days >= 0
    }

    var isExpired: Bool {
        guard let days = daysUntilExpiry else { return false }
        return days < 0
    }

    var totalConsumedQuantity: Decimal {
        consumptions?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0
    }

    var totalConsumedQuantityInGrams: Decimal {
        consumptions?.reduce(Decimal(0)) { $0 + $1.unit.convertToGrams($1.quantity) } ?? 0
    }

    var totalRefilledQuantity: Decimal {
        refills?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0
    }

    var totalRefilledQuantityInGrams: Decimal {
        refills?.reduce(Decimal(0)) { $0 + $1.unit.convertToGrams($1.quantity) } ?? 0
    }

    init(
        name: String,
        quantity: Decimal = 0.0,
        currentQuantity: Decimal = 0.0,
        unit: FoodUnit = .gram,
        category: FoodCategory = .other,
        expiryDate: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.currentQuantity = currentQuantity
        self.unit = unit
        self.category = category
        self.expiryDate = expiryDate
        self.createdAt = createdAt
    }
}

enum FoodUnit: String, CaseIterable, Codable {
    case gram = "Gram"
    case kilogram = "Kilogram"
    case milliliter = "Milliliter"
    case liter = "Liter"
    case piece = "Piece"
    case tablespoon = "Tablespoon"
    case teaspoon = "Teaspoon"
    case cup = "Cup"

    var abbreviation: String {
        switch self {
        case .gram:       return "g"
        case .kilogram:   return "kg"
        case .milliliter: return "ml"
        case .liter:      return "l"
        case .piece:      return "pcs"
        case .tablespoon: return "tbsp"
        case .teaspoon:   return "tsp"
        case .cup:        return "cup"
        }
    }

    func convertToGrams(_ quantity: Decimal) -> Decimal {
        switch self {
        case .gram:       return quantity
        case .kilogram:   return quantity * 1000
        case .milliliter: return quantity
        case .liter:      return quantity * 1000
        case .piece:      return quantity * 100
        case .tablespoon: return quantity * 15
        case .teaspoon:   return quantity * 5
        case .cup:        return quantity * 240
        }
    }

    func convertToGrams(_ quantity: Int) -> Int {
        switch self {
        case .gram:       return quantity
        case .kilogram:   return quantity * 1000
        case .milliliter: return quantity
        case .liter:      return quantity * 1000
        case .piece:      return quantity * 100
        case .tablespoon: return quantity * 15
        case .teaspoon:   return quantity * 5
        case .cup:        return quantity * 240
        }
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
