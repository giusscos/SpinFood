import Foundation

/// What to cook next, from the person's own recipes and Foo's. Saving food that's about to expire
/// always comes first. Powers Tonight's idea in the book and the recipe named in reminders.
struct CookSuggestion {
    enum Reason {
        case usesExpiring([String])
        case haveEverything
        case missing([String])
    }

    let name: String
    let emoji: String?
    let route: ReminderRoute
    let reason: Reason

    /// A recipe's fit with the kitchen right now.
    struct Candidate {
        let name: String
        let emoji: String?
        let route: ReminderRoute
        let foodIDs: Set<UUID>
        let haveCount: Int
        let missingNames: [String]
        let cookedRecently: Bool
        let isOwnRecipe: Bool
    }

    static func candidates(foods: [FoodModel], recipes: [RecipeModel], now: Date = .now) -> [Candidate] {
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now

        let own = recipes.compactMap { recipe -> Candidate? in
            let ingredients = recipe.ingredients ?? []
            guard !ingredients.isEmpty else { return nil }
            let missing = recipe.missingIngredients
            return Candidate(
                name: recipe.name,
                emoji: StarterRecipe.all.first { $0.id == recipe.catalogID }?.emoji,
                route: .bookRecipe(recipe.id),
                foodIDs: Set(ingredients.compactMap { $0.ingredient?.id }),
                haveCount: ingredients.count - missing.count,
                missingNames: missing.compactMap { $0.ingredient?.name },
                cookedRecently: recipe.cookedAt.contains { $0 > recentCutoff },
                isOwnRecipe: true
            )
        }

        let inBook = Set(recipes.compactMap(\.catalogID))
        let built = StarterRecipe.all
            .filter { !inBook.contains($0.id) }
            .map { recipe -> Candidate in
                let idea = RecipeIdea(recipe: recipe, foods: foods)
                return Candidate(
                    name: recipe.localizedName,
                    emoji: recipe.emoji,
                    route: .recipeIdea(recipe.id),
                    foodIDs: Set(idea.items.compactMap { $0.isInStock ? $0.food?.id : nil }),
                    haveCount: idea.items.count - idea.missing.count,
                    missingNames: idea.missing.map(\.grocery.name),
                    cookedRecently: false,
                    isOwnRecipe: false
                )
            }

        return own + built
    }

    /// The recipe that uses the most of `targets`, or `nil` when none uses any of them.
    static func best(using targets: [FoodModel], in candidates: [Candidate]) -> CookSuggestion? {
        let matches = candidates.compactMap { candidate -> (candidate: Candidate, used: [FoodModel])? in
            let used = targets.filter { candidate.foodIDs.contains($0.id) }
            return used.isEmpty ? nil : (candidate, used)
        }
        let ranked = matches.sorted { first, second in
            if first.used.count != second.used.count { return first.used.count > second.used.count }
            if first.candidate.cookedRecently != second.candidate.cookedRecently { return second.candidate.cookedRecently }
            if first.candidate.missingNames.count != second.candidate.missingNames.count {
                return first.candidate.missingNames.count < second.candidate.missingNames.count
            }
            if first.candidate.isOwnRecipe != second.candidate.isOwnRecipe { return first.candidate.isOwnRecipe }
            return first.candidate.name < second.candidate.name
        }
        return ranked.first.map { suggestion(from: $0.candidate, reason: .usesExpiring($0.used.map(\.name))) }
    }

    /// One idea for today. It changes from day to day, so the book doesn't always open on the same one.
    static func tonight(foods: [FoodModel], recipes: [RecipeModel], now: Date = .now) -> CookSuggestion? {
        let candidates = candidates(foods: foods, recipes: recipes, now: now)

        let expiring = foods.filter { !$0.isOutOfStock && $0.isExpiringSoon }
        if let saving = best(using: expiring, in: candidates) { return saving }

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        let fresh = candidates.filter { !$0.cookedRecently }

        let ready = fresh.filter { $0.missingNames.isEmpty && $0.haveCount > 0 }.sorted { $0.name < $1.name }
        if !ready.isEmpty {
            return suggestion(from: ready[dayOfYear % ready.count], reason: .haveEverything)
        }

        let almost = fresh.filter { (1...2).contains($0.missingNames.count) && $0.haveCount >= 2 }
        guard let fewest = almost.map(\.missingNames.count).min() else { return nil }
        let closest = almost.filter { $0.missingNames.count == fewest }.sorted { $0.name < $1.name }
        let pick = closest[dayOfYear % closest.count]
        return suggestion(from: pick, reason: .missing(pick.missingNames))
    }

    private static func suggestion(from candidate: Candidate, reason: Reason) -> CookSuggestion {
        CookSuggestion(name: candidate.name, emoji: candidate.emoji, route: candidate.route, reason: reason)
    }
}
