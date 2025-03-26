//
//  FoodModel.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class FoodModel {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Decimal = 0.0
    var currentQuantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var createdAt: Date = Date.now
    var rating: Int = 0
    
    @Relationship(inverse: \RecipeFoodModel.ingredient) var recipes: [RecipeFoodModel]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \FoodConsumptionModel.food) var consumptions: [FoodConsumptionModel]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \FoodRefillModel.food) var refills: [FoodRefillModel]? = []
    
    // Keeping this for backward compatibility
    var eatenAt: [Date] = []
    
    var totalConsumedQuantity: Decimal {
        guard let consumptions = consumptions else { return 0 }
        return consumptions.reduce(Decimal(0)) { result, consumption in
            return result + consumption.quantity
        }
    }
    
    var totalConsumedQuantityInGrams: Decimal {
        guard let consumptions = consumptions else { return 0 }
        return consumptions.reduce(Decimal(0)) { result, consumption in
            return result + consumption.unit.convertToGrams(consumption.quantity)
        }
    }
    
    var totalRefilledQuantity: Decimal {
        guard let refills = refills else { return 0 }
        return refills.reduce(Decimal(0)) { result, refill in
            return result + refill.quantity
        }
    }
    
    var totalRefilledQuantityInGrams: Decimal {
        guard let refills = refills else { return 0 }
        return refills.reduce(Decimal(0)) { result, refill in
            return result + refill.unit.convertToGrams(refill.quantity)
        }
    }
    
    init(name: String, quantity: Decimal = 0.0, currentQuantity: Decimal = 0.0, unit: FoodUnit = FoodUnit.gram, createdAt: Date = Date.now) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.currentQuantity = currentQuantity
        self.unit = unit
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
        case .gram:
            return "g"
        case .kilogram:
            return "kg"
        case .milliliter:
            return "ml"
        case .liter:
            return "l"
        case .piece:
            return "pcs"
        case .tablespoon:
            return "tbsp"
        case .teaspoon:
            return "tsp"
        case .cup:
            return "cup"
        }
    }
    
    func convertToGrams(_ quantity: Decimal) -> Decimal {
        switch self {
        case .gram:
            return quantity
        case .kilogram:
            return quantity * 1000
        case .milliliter:
            return quantity
        case .liter:
            return quantity * 1000
        case .piece:
            return quantity * 100
        case .tablespoon:
            return quantity * 15
        case .teaspoon:
            return quantity * 5
        case .cup:
            return quantity * 240
        }
    }
    
    func convertToGrams(_ quantity: Int) -> Int {
        switch self {
        case .gram:
            return quantity
        case .kilogram:
            return quantity * 1000
        case .milliliter:
            return quantity
        case .liter:
            return quantity * 1000
        case .piece:
            return quantity * 100
        case .tablespoon:
            return quantity * 15
        case .teaspoon:
            return quantity * 5
        case .cup:
            return quantity * 240
        }
    }
}
