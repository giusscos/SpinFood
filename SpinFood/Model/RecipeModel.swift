import Foundation
import SwiftData

@Model
final class RecipeModel {
    var id: UUID = UUID()
    var name: String = ""
    var descriptionRecipe: String = ""
    @Attribute(.externalStorage) var image: Data?
    var duration: TimeInterval = 0.0
    var servings: Int = 2
    var createdAt: Date = Date.now
    var rating: Int = 0
    var order: Int = 0
    var cookedAt: [Date] = []

    @Relationship var ingredients: [RecipeFoodModel]? = []
    @Relationship var steps: [StepRecipe]? = []

    var lastStepIndex: Int = 0

    var canCook: Bool {
        guard let ingredients, !ingredients.isEmpty else { return false }
        return ingredients.allSatisfy { recipeFood in
            guard let ingredient = recipeFood.ingredient else { return false }
            return ingredient.currentQuantity >= recipeFood.quantityNeeded
        }
    }

    var missingIngredients: [RecipeFoodModel] {
        guard let ingredients else { return [] }
        return ingredients.filter { recipeFood in
            guard let ingredient = recipeFood.ingredient else { return true }
            return ingredient.currentQuantity < recipeFood.quantityNeeded
        }
    }

    init(
        name: String,
        descriptionRecipe: String = "",
        image: Data? = nil,
        duration: TimeInterval = 0.0,
        servings: Int = 2,
        ingredients: [RecipeFoodModel]? = nil,
        steps: [StepRecipe]? = nil
    ) {
        self.name = name
        self.descriptionRecipe = descriptionRecipe
        self.image = image
        self.duration = duration
        self.servings = servings
        self.ingredients = ingredients
        self.steps = steps
    }
}

@Model
class StepRecipe {
    var id: UUID = UUID()
    var text: String = ""
    @Attribute(.externalStorage) var image: Data?
    var createdAt: Date = Date.now

    @Relationship var recipes: RecipeModel? = nil

    init(text: String, image: Data? = nil) {
        self.text = text
        self.image = image
    }
}
