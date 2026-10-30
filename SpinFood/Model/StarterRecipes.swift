import Foundation
import SwiftData
import UIKit

/// A recipe that ships with Foo. Each one is built around food that commonly gets thrown away,
/// and its ingredients point at `GroceryCatalog` items so it can be matched against the pantry.
struct StarterRecipe: Identifiable, Decodable {
    struct Ingredient: Decodable {
        let id: String
        let quantity: Decimal
    }

    struct Step: Decodable {
        let text: [String: String]
        let timerMinutes: Int?
    }

    let id: String
    let emoji: String
    let minutes: Int
    let servings: Int
    let difficulty: RecipeDifficulty
    let tags: [RecipeTag]
    let name: [String: String]
    let summary: [String: String]
    let ingredients: [Ingredient]
    let steps: [Step]

    static let all: [StarterRecipe] = {
        guard let url = Bundle.main.url(forResource: "StarterRecipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let recipes = try? JSONDecoder().decode([StarterRecipe].self, from: data) else {
            assertionFailure("StarterRecipes.json is missing or invalid")
            return []
        }
        return recipes
    }()

    var localizedName: String { Self.localized(name) }
    var localizedSummary: String { Self.localized(summary) }

    static func localized(_ strings: [String: String]) -> String {
        strings[AppLanguage.current] ?? strings["en"] ?? ""
    }

    /// Copies the recipe into the book. Ingredients link to what's already in the pantry; anything
    /// missing is added out of stock, which is what puts it on the shopping list.
    @MainActor
    @discardableResult
    func addToBook(foods: [FoodModel], in context: ModelContext) -> RecipeModel {
        let recipe = RecipeModel(
            name: localizedName,
            descriptionRecipe: localizedSummary,
            image: illustration(),
            duration: TimeInterval(minutes * 60),
            servings: servings,
            difficulty: difficulty,
            tags: tags
        )
        recipe.catalogID = id
        context.insert(recipe)

        var pantry = foods
        recipe.ingredients = ingredients.compactMap { ingredient in
            guard let item = GroceryCatalog.item(id: ingredient.id) else { return nil }
            let food: FoodModel
            if let existing = item.pantryFood(in: pantry) {
                food = existing
            } else {
                food = item.makeFood(quantity: item.packQuantity, currentQuantity: 0, expiryDate: nil)
                context.insert(food)
                pantry.append(food)
            }
            return RecipeFoodModel(
                ingredient: food,
                quantityNeeded: food.unit.converted(ingredient.quantity, from: item.unit)
            )
        }

        recipe.steps = steps.enumerated().map { index, step in
            let recipeStep = StepRecipe(text: "")
            recipeStep.order = index
            var blocks = [StepBlock(type: .text, order: 0, textContent: Self.localized(step.text))]
            if let minutes = step.timerMinutes {
                blocks.append(StepBlock(
                    type: .timer,
                    order: 1,
                    timerDuration: TimeInterval(minutes * 60),
                    timerLabel: localizedName
                ))
            }
            recipeStep.blocks = blocks
            return recipeStep
        }

        context.saveConfirmedChanges()
        return recipe
    }

    /// A warm card with the recipe's emoji, so the book never shows an empty photo frame.
    private func illustration() -> Data? {
        let palette: [UIColor] = [
            UIColor(red: 0.98, green: 0.87, blue: 0.74, alpha: 1),
            UIColor(red: 0.96, green: 0.91, blue: 0.70, alpha: 1),
            UIColor(red: 0.83, green: 0.90, blue: 0.76, alpha: 1),
            UIColor(red: 0.97, green: 0.80, blue: 0.75, alpha: 1),
        ]
        let background = palette[id.utf8.reduce(0) { $0 + Int($1) } % palette.count]
        let size = CGSize(width: 840, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            background.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let text = NSAttributedString(string: emoji, attributes: [.font: UIFont.systemFont(ofSize: 300)])
            let textSize = text.size()
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2))
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Matching against the pantry

/// How a starter recipe fits what's in the kitchen right now.
struct RecipeIdea: Identifiable {
    let recipe: StarterRecipe
    let items: [Item]

    struct Item: Identifiable {
        let grocery: GroceryItem
        let quantity: Decimal
        let food: FoodModel?
        let isInStock: Bool

        var id: String { grocery.id }
        var isExpiringSoon: Bool { isInStock && (food?.isExpiringSoon ?? false) }
    }

    var id: String { recipe.id }
    var missing: [Item] { items.filter { !$0.isInStock } }
    var expiring: [Item] { items.filter(\.isExpiringSoon) }

    init(recipe: StarterRecipe, foods: [FoodModel]) {
        self.recipe = recipe
        self.items = recipe.ingredients.compactMap { ingredient in
            guard let grocery = GroceryCatalog.item(id: ingredient.id) else { return nil }
            let food = grocery.pantryFood(in: foods)
            let isInStock = food.map { food in
                !food.isOutOfStock
                    && food.currentQuantity >= food.unit.converted(ingredient.quantity, from: grocery.unit)
            } ?? false
            return Item(grocery: grocery, quantity: ingredient.quantity, food: food, isInStock: isInStock)
        }
    }
}

extension Array where Element == RecipeModel {
    /// Recipes from Foo's own collection are free, so only the person's own recipes fill the free book.
    var countTowardFreeLimit: Int {
        filter { $0.catalogID == nil }.count
    }
}
