//
//  FoodModal.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class FoodModal {
    var id: UUID = UUID()
    var name: String = ""
    var quantity: Decimal = 0.0
    var currentQuantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var image: Data?
    var createdAt: Date = Date.now
    var rating: Int = 0
    
    var recipes: [RecipeFoodModal]? = []
    
    init(name: String, quantity: Decimal = 0.0, currentQuantity: Decimal = 0.0, unit: FoodUnit = FoodUnit.gram, image: Data? = nil, createdAt: Date = Date.now) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.currentQuantity = currentQuantity
        self.unit = unit
        self.image = image
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
}
