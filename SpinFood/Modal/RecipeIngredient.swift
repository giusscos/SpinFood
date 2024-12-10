//
//  RecipeIngredient.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class RecipeIngredient {
    var id: UUID = UUID()
    var ingredient: IngredientModal?
    var quantityNeeded: Decimal = 0.0
    
    init(id: UUID, ingredient: IngredientModal? = nil, quantityNeeded: Decimal) {
        self.id = id
        self.ingredient = ingredient
        self.quantityNeeded = quantityNeeded
    }
}
