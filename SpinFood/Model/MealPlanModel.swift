import Foundation
import SwiftData

enum MealSlot: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var localizedName: String {
        switch self {
        case .breakfast: return String(localized: "Breakfast")
        case .lunch:     return String(localized: "Lunch")
        case .dinner:    return String(localized: "Dinner")
        case .snack:     return String(localized: "Snack")
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon"
        case .lunch:     return "sun.max"
        case .dinner:    return "moon.stars"
        case .snack:     return "leaf"
        }
    }

    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch:     return 1
        case .dinner:    return 2
        case .snack:     return 3
        }
    }
}

@Model
final class MealPlanEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var slot: MealSlot = MealSlot.dinner

    @Relationship var recipe: RecipeModel? = nil

    init(date: Date, slot: MealSlot = .dinner, recipe: RecipeModel? = nil) {
        self.date = date
        self.slot = slot
        self.recipe = recipe
    }
}
