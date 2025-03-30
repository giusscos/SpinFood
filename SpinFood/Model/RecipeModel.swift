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
    
    // Store steps as arrays instead of separate model objects
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
    
    // Helper method to add a step
    func addStep(instructions: String, image: Data? = nil) {
        stepInstructions.append(instructions)
        stepImages.append(image)
    }
    
    // Helper method to update a step
    func updateStep(at index: Int, instructions: String, image: Data?) {
        guard index >= 0 && index < stepInstructions.count else { return }
        stepInstructions[index] = instructions
        stepImages[index] = image
    }
    
    // Helper method to remove a step
    func removeStep(at index: Int) {
        guard index >= 0 && index < stepInstructions.count else { return }
        stepInstructions.remove(at: index)
        stepImages.remove(at: index)
    }
}
