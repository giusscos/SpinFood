//
//  FoodRefillModel.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class FoodRefillModel {
    var id: UUID = UUID()
    var refilledAt: Date = Date.now
    var quantity: Decimal = 0.0 // How much was refilled
    var unit: FoodUnit = FoodUnit.gram
    @Relationship var food: FoodModel?
    
    init(refilledAt: Date = Date.now, quantity: Decimal, unit: FoodUnit = FoodUnit.gram, food: FoodModel? = nil) {
        self.id = UUID()
        self.refilledAt = refilledAt
        self.quantity = quantity
        self.unit = unit
        self.food = food
    }
} 