import Foundation
import WidgetKit

// MARK: - Snapshot models (shared with widget via App Group UserDefaults)

struct WidgetSnapshot: Codable, Equatable {
    var pantryAlertCount: Int
    var expiringCount: Int
    var lowStockCount: Int
    var expiredCount: Int
    var todayMeals: [WidgetMealItem]
    var suggestedRecipeName: String?
    var suggestedRecipeEmoji: String
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        pantryAlertCount: 0,
        expiringCount: 0,
        lowStockCount: 0,
        expiredCount: 0,
        todayMeals: [],
        suggestedRecipeName: nil,
        suggestedRecipeEmoji: "🍽️",
        updatedAt: .now
    )
}

struct WidgetMealItem: Codable, Equatable, Identifiable {
    var id: String
    var slot: String
    var slotIcon: String
    var recipeName: String
}

enum WidgetSnapshotStore {
    static func load() -> WidgetSnapshot {
        guard let data = AppGroupContainer.sharedDefaults.data(forKey: AppGroupContainer.widgetSnapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        AppGroupContainer.sharedDefaults.set(data, forKey: AppGroupContainer.widgetSnapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func refresh(foods: [FoodModel], meals: [MealPlanEntry], recipes: [RecipeModel]) {
        let expiring = foods.filter { $0.isExpiringSoon }.count
        let expired = foods.filter { $0.isExpired }.count
        let lowStock = foods.filter { $0.isLowStock }.count

        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let todayMeals = meals
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.slot.sortOrder < $1.slot.sortOrder }
            .compactMap { entry -> WidgetMealItem? in
                guard let recipe = entry.recipe else { return nil }
                return WidgetMealItem(
                    id: entry.id.uuidString,
                    slot: entry.slot.localizedName,
                    slotIcon: entry.slot.icon,
                    recipeName: recipe.name
                )
            }

        let suggested = recipes.randomElement()
        let emoji: String = {
            guard let data = suggested?.image else { return "🍽️" }
            return data.isEmpty ? "🍽️" : "📖"
        }()

        let snapshot = WidgetSnapshot(
            pantryAlertCount: expiring + expired + lowStock,
            expiringCount: expiring,
            lowStockCount: lowStock,
            expiredCount: expired,
            todayMeals: todayMeals,
            suggestedRecipeName: suggested?.name,
            suggestedRecipeEmoji: emoji,
            updatedAt: .now
        )
        save(snapshot)
    }
}
