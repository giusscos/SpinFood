import Foundation

enum AppGroupContainer {
    static let identifier = "group.giusscos.SpinFood"
    static let widgetSnapshotKey = "widgetSnapshot"

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
}
