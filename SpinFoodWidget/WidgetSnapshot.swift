import Foundation
import WidgetKit

enum AppGroupContainer {
    static let identifier = "group.giusscos.SpinFood"
    static let widgetSnapshotKey = "widgetSnapshot"
    static let pendingCookRecipeIDKey = "pendingCookRecipeID"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

struct WidgetSnapshot: Codable, Equatable {
    var pantryAlertCount: Int
    var expiringCount: Int
    var lowStockCount: Int
    var expiredCount: Int
    var todayMeals: [WidgetMealItem]
    var suggestedRecipeName: String?
    var suggestedRecipeEmoji: String
    var cookableRecipes: [WidgetCookableRecipe]
    var selectedCookableRecipeID: String?
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        pantryAlertCount: 0,
        expiringCount: 0,
        lowStockCount: 0,
        expiredCount: 0,
        todayMeals: [],
        suggestedRecipeName: nil,
        suggestedRecipeEmoji: "🍽️",
        cookableRecipes: [],
        selectedCookableRecipeID: nil,
        updatedAt: .now
    )

    var selectedCookableRecipe: WidgetCookableRecipe? {
        if let selectedCookableRecipeID,
           let match = cookableRecipes.first(where: { $0.id == selectedCookableRecipeID }) {
            return match
        }
        return cookableRecipes.first
    }

    enum CodingKeys: String, CodingKey {
        case pantryAlertCount, expiringCount, lowStockCount, expiredCount
        case todayMeals, suggestedRecipeName, suggestedRecipeEmoji
        case cookableRecipes, selectedCookableRecipeID, updatedAt
    }

    init(
        pantryAlertCount: Int,
        expiringCount: Int,
        lowStockCount: Int,
        expiredCount: Int,
        todayMeals: [WidgetMealItem],
        suggestedRecipeName: String?,
        suggestedRecipeEmoji: String,
        cookableRecipes: [WidgetCookableRecipe],
        selectedCookableRecipeID: String?,
        updatedAt: Date
    ) {
        self.pantryAlertCount = pantryAlertCount
        self.expiringCount = expiringCount
        self.lowStockCount = lowStockCount
        self.expiredCount = expiredCount
        self.todayMeals = todayMeals
        self.suggestedRecipeName = suggestedRecipeName
        self.suggestedRecipeEmoji = suggestedRecipeEmoji
        self.cookableRecipes = cookableRecipes
        self.selectedCookableRecipeID = selectedCookableRecipeID
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pantryAlertCount = try container.decode(Int.self, forKey: .pantryAlertCount)
        expiringCount = try container.decode(Int.self, forKey: .expiringCount)
        lowStockCount = try container.decode(Int.self, forKey: .lowStockCount)
        expiredCount = try container.decode(Int.self, forKey: .expiredCount)
        todayMeals = try container.decode([WidgetMealItem].self, forKey: .todayMeals)
        suggestedRecipeName = try container.decodeIfPresent(String.self, forKey: .suggestedRecipeName)
        suggestedRecipeEmoji = try container.decodeIfPresent(String.self, forKey: .suggestedRecipeEmoji) ?? "🍽️"
        cookableRecipes = try container.decodeIfPresent([WidgetCookableRecipe].self, forKey: .cookableRecipes) ?? []
        selectedCookableRecipeID = try container.decodeIfPresent(String.self, forKey: .selectedCookableRecipeID)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }
}

struct WidgetMealItem: Codable, Equatable, Identifiable {
    var id: String
    var slot: String
    var slotIcon: String
    var recipeName: String
}

struct WidgetCookableRecipe: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var durationText: String
    var ingredientCount: Int
    var imageJPEG: Data?
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

    static func advanceCookableRecipe() {
        var snapshot = load()
        guard snapshot.cookableRecipes.count > 1 else { return }
        let currentIndex = snapshot.cookableRecipes.firstIndex(where: { $0.id == snapshot.selectedCookableRecipeID }) ?? 0
        let nextIndex = (currentIndex + 1) % snapshot.cookableRecipes.count
        snapshot.selectedCookableRecipeID = snapshot.cookableRecipes[nextIndex].id
        snapshot.updatedAt = .now
        save(snapshot)
    }
}
