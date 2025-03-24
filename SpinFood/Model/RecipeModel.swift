//
//  RecipeModel.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import Foundation
import SwiftData

@Model
class RecipeModel {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionRecipe: String = ""
    @Attribute(.externalStorage) var image: Data?
    var duration: TimeInterval = 0.0
    var createdAt: Date = Date.now
    var rating: Int = 0
    var steps: [String] = []
    
    var cookedAt: [Date] = []
    
    @Relationship var ingredients: [RecipeFoodModel]? = []
    
    init(name: String, descriptionRecipe: String = "", image: Data? = nil, createdAt: Date = Date.now, ingredients: [RecipeFoodModel]? = nil, steps: [String] = [], duration: TimeInterval = 0.0) {
        self.id = UUID()
        self.name = name
        self.descriptionRecipe = descriptionRecipe
        self.image = image
        self.duration = duration
        self.createdAt = createdAt
        self.ingredients = ingredients
        self.steps = steps
    }
}
