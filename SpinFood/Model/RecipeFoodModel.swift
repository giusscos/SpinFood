//
//  RecipeFoodModel.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
final class RecipeFoodModel {
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
