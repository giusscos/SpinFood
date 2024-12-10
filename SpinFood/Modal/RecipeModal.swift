//
//  RecipeModal.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class RecipeModal {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionRecipe: String = ""
    var image: Data?
    var duration: Decimal = 0.0
    var createdAt: Date = Date.now
    var rating: Int = 0
    var steps: [String]
    
    @Relationship var ingredients: [RecipeIngredient]?
    
    init(name: String, descriptionRecipe: String = "", image: Data? = nil, createdAt: Date = Date.now, ingredients: [RecipeIngredient]? = nil, steps: [String] = []) {
        self.id = UUID()
        self.name = name
        self.descriptionRecipe = descriptionRecipe
        self.image = image
        self.createdAt = createdAt
        self.ingredients = ingredients
    }
}
