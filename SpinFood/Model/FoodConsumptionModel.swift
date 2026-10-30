
import Foundation
import SwiftData

@Model
final class FoodConsumptionModel {
    var id: UUID = UUID()
    var consumedAt: Date = Date.now
    var quantity: Decimal = 0.0
    var unit: FoodUnit = FoodUnit.gram
    /// Eaten around its expiry date, so it counts as food saved from the bin.
    var rescued: Bool = false
    @Relationship var food: FoodModel?
    
    init(consumedAt: Date = Date.now, quantity: Decimal, unit: FoodUnit = FoodUnit.gram, food: FoodModel? = nil, rescued: Bool = false) {
        self.id = UUID()
        self.consumedAt = consumedAt
        self.quantity = quantity
        self.unit = unit
        self.food = food
        self.rescued = rescued
    }
} 
