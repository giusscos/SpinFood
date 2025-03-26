
import Foundation
import SwiftData

@Model
class FoodConsumptionModel {
    var id: UUID = UUID()
    var consumedAt: Date = Date.now
    var quantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    @Relationship var food: FoodModel?
    
    init(consumedAt: Date = Date.now, quantity: Decimal, unit: FoodUnit = FoodUnit.gram, food: FoodModel? = nil) {
        self.id = UUID()
        self.consumedAt = consumedAt
        self.quantity = quantity
        self.unit = unit
        self.food = food
    }
} 
