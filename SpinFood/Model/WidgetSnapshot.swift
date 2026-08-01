import Foundation
import UIKit
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

        let previous = load()
        let cookableRecipes = recipes
            .filter { $0.canCook && !($0.steps ?? []).isEmpty }
            .sorted {
                if $0.order != $1.order { return $0.order < $1.order }
                return $0.name < $1.name
            }
            .prefix(12)
            .map { recipe -> WidgetCookableRecipe in
                WidgetCookableRecipe(
                    id: recipe.id.uuidString,
                    name: recipe.name,
                    durationText: Self.durationText(for: recipe.duration),
                    ingredientCount: recipe.ingredients?.count ?? 0,
                    imageJPEG: Self.thumbnailJPEG(from: recipe.image)
                )
            }

        let selectedID: String? = {
            if let previousID = previous.selectedCookableRecipeID,
               cookableRecipes.contains(where: { $0.id == previousID }) {
                return previousID
            }
            return cookableRecipes.first?.id
        }()

        let snapshot = WidgetSnapshot(
            pantryAlertCount: expiring + expired + lowStock,
            expiringCount: expiring,
            lowStockCount: lowStock,
            expiredCount: expired,
            todayMeals: todayMeals,
            suggestedRecipeName: suggested?.name,
            suggestedRecipeEmoji: emoji,
            cookableRecipes: Array(cookableRecipes),
            selectedCookableRecipeID: selectedID,
            updatedAt: .now
        )
        save(snapshot)
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

    private static func durationText(for duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int((duration / 60).rounded()))
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 { return "\(hours)h" }
            return "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes) mins"
    }

    private static func thumbnailJPEG(from data: Data?, maxDimension: CGFloat = 120, quality: CGFloat = 0.7) -> Data? {
        guard let data, let image = UIImage(data: data) else { return nil }
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
