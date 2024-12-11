//
//  RecipeFood.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class RecipeFoodModal {
    var id: UUID = UUID()
    var ingredient: FoodModal?
    var quantityNeeded: Decimal = 0.0
    
    @Relationship var recipes: [RecipeModal]? = []
    
    init(ingredient: FoodModal? = nil, quantityNeeded: Decimal) {
        self.id = UUID()
        self.ingredient = ingredient
        self.quantityNeeded = quantityNeeded
    }
}
