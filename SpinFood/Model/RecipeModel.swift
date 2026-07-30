import Foundation
import SwiftData

enum RecipeDifficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var localizedName: String {
        switch self {
        case .easy:   return String(localized: "Easy")
        case .medium: return String(localized: "Medium")
        case .hard:   return String(localized: "Hard")
        }
    }

    var icon: String {
        switch self {
        case .easy:   return "gauge.low"
        case .medium: return "gauge.medium"
        case .hard:   return "gauge.high"
        }
    }
}

enum RecipeTag: String, CaseIterable, Codable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
    case quick = "Quick"
    case healthy = "Healthy"
    case spicy = "Spicy"

    var localizedName: String {
        switch self {
        case .vegetarian: return String(localized: "Vegetarian")
        case .vegan:      return String(localized: "Vegan")
        case .glutenFree: return String(localized: "Gluten Free")
        case .dairyFree:  return String(localized: "Dairy Free")
        case .quick:      return String(localized: "Quick")
        case .healthy:    return String(localized: "Healthy")
        case .spicy:      return String(localized: "Spicy")
        }
    }

    var icon: String {
        switch self {
        case .vegetarian: return "leaf"
        case .vegan:      return "leaf.fill"
        case .glutenFree: return "g.square"
        case .dairyFree:  return "d.square"
        case .quick:      return "clock"
        case .healthy:    return "heart"
        case .spicy:      return "flame"
        }
    }
}

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
    var difficulty: RecipeDifficulty? = nil
    var tags: [RecipeTag] = []

    @Relationship var ingredients: [RecipeFoodModel]? = []
    @Relationship var steps: [StepRecipe]? = []
    @Relationship(deleteRule: .nullify, inverse: \MealPlanEntry.recipe) var mealPlanEntries: [MealPlanEntry]? = []

    var lastStepIndex: Int = 0
    /// True while a step-by-step cook session is in progress (survives dismiss until confirm eat).
    var cookingInProgress: Bool = false
    /// Serving scale chosen at the start of the current cook session.
    var lastCookServingScale: Double = 1

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

    /// Maximum servings the pantry can support for this recipe (at least 1 when empty/unconstrained).
    var maxCookableServings: Int {
        guard let ingredients, !ingredients.isEmpty else { return 20 }
        let baseServings = max(1, servings)
        var maxServings = 20

        for recipeFood in ingredients {
            guard let food = recipeFood.ingredient else { return 0 }
            guard recipeFood.quantityNeeded > 0 else { continue }

            let batches = food.currentQuantity / recipeFood.quantityNeeded
            let servingsFromIngredient = Int(truncating: (batches * Decimal(baseServings)) as NSDecimalNumber)
            maxServings = min(maxServings, max(0, servingsFromIngredient))
        }

        return maxServings
    }

    func finishCookingSession() {
        cookingInProgress = false
        lastStepIndex = 0
        lastCookServingScale = 1
    }

    init(
        name: String,
        descriptionRecipe: String = "",
        image: Data? = nil,
        duration: TimeInterval = 0.0,
        servings: Int = 2,
        ingredients: [RecipeFoodModel]? = nil,
        steps: [StepRecipe]? = nil,
        difficulty: RecipeDifficulty? = nil,
        tags: [RecipeTag] = []
    ) {
        self.name = name
        self.descriptionRecipe = descriptionRecipe
        self.image = image
        self.duration = duration
        self.servings = servings
        self.ingredients = ingredients
        self.steps = steps
        self.difficulty = difficulty
        self.tags = tags
    }
}

@Model
class StepRecipe {
    var id: UUID = UUID()
    var text: String = ""
    @Attribute(.externalStorage) var image: Data?
    var createdAt: Date = Date.now
    var order: Int = 0
    /// Suggested cook duration for this step (seconds). `0` means no auto-timer.
    var suggestedDuration: TimeInterval = 0

    @Relationship(deleteRule: .cascade) var blocks: [StepBlock]? = []
    @Relationship var recipes: RecipeModel? = nil

    init(text: String, image: Data? = nil, suggestedDuration: TimeInterval = 0) {
        self.text = text
        self.image = image
        self.suggestedDuration = suggestedDuration
    }

    var sortedBlocks: [StepBlock] {
        (blocks ?? []).sorted { $0.order < $1.order }
    }

    var hasSuggestedTimer: Bool { suggestedDuration > 0 }
}
