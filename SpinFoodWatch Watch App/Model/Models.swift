//
//  Models.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
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
    
    var totalConsumedQuantity: Decimal {
        guard let consumptions = consumptions else { return 0 }
        return consumptions.reduce(Decimal(0)) { result, consumption in
            return result + consumption.quantity
        }
    }
    
    var totalRefilledQuantity: Decimal {
        guard let refills = refills else { return 0 }
        return refills.reduce(Decimal(0)) { result, refill in
            return result + refill.quantity
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
        case .gram: return "g"
        case .kilogram: return "kg"
        case .milliliter: return "ml"
        case .liter: return "l"
        case .piece: return "pcs"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        case .cup: return "cup"
        }
    }
    
    func convertToGrams(_ quantity: Decimal) -> Decimal {
        switch self {
        case .gram: return quantity
        case .kilogram: return quantity * 1000
        case .milliliter: return quantity
        case .liter: return quantity * 1000
        case .piece: return quantity * 100
        case .tablespoon: return quantity * 15
        case .teaspoon: return quantity * 5
        case .cup: return quantity * 240
        }
    }
}

@Model
class RecipeModel {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionRecipe: String = ""
    @Attribute(.externalStorage) var image: Data?
    var duration: TimeInterval = 0.0
    var createdAt: Date = Date.now
    var rating: Int = 0
    
    var stepInstructions: [String] = []
    @Attribute(.externalStorage) var stepImages: [Data?] = []
    var lastStepIndex: Int = 0
    
    var cookedAt: [Date] = []
    
    @Relationship var ingredients: [RecipeFoodModel]? = []
    
    init(name: String, descriptionRecipe: String = "", image: Data? = nil, createdAt: Date = Date.now, ingredients: [RecipeFoodModel]? = nil, stepInstructions: [String] = [], stepImages: [Data?] = [], duration: TimeInterval = 0.0) {
        self.id = UUID()
        self.name = name
        self.descriptionRecipe = descriptionRecipe
        self.image = image
        self.duration = duration
        self.createdAt = createdAt
        self.ingredients = ingredients
        self.stepInstructions = stepInstructions
        self.stepImages = stepImages
    }
}

@Model
class RecipeFoodModel {
    var id: UUID = UUID()
    @Relationship var ingredient: FoodModel?
    var quantityNeeded: Decimal = 0.0
    
    @Relationship var recipes: [RecipeModel]? = []
    
    init(ingredient: FoodModel? = nil, quantityNeeded: Decimal) {
        self.id = UUID()
        self.ingredient = ingredient
        self.quantityNeeded = quantityNeeded
    }
}

@Model
class FoodRefillModel {
    var id: UUID = UUID()
    @Relationship var food: FoodModel?
    var quantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var date: Date = Date.now
    
    init(food: FoodModel? = nil, quantity: Decimal, unit: FoodUnit = FoodUnit.gram, date: Date = Date.now) {
        self.id = UUID()
        self.food = food
        self.quantity = quantity
        self.unit = unit
        self.date = date
    }
}

@Model
class FoodConsumptionModel {
    var id: UUID = UUID()
    @Relationship var food: FoodModel?
    var quantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    var date: Date = Date.now
    
    init(food: FoodModel? = nil, quantity: Decimal, unit: FoodUnit = FoodUnit.gram, date: Date = Date.now) {
        self.id = UUID()
        self.food = food
        self.quantity = quantity
        self.unit = unit
        self.date = date
    }
} 