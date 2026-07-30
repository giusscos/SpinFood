import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleAll(foods: [FoodModel]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for food in foods {
            scheduleExpiryNotifications(for: food)
            if food.isLowStock {
                scheduleLowStockNotification(for: food)
            }
        }
    }

    private func scheduleExpiryNotifications(for food: FoodModel) {
        guard let expiry = food.expiryDate else { return }
        let calendar = Calendar.current
        let prefix = food.emoji.isEmpty ? "" : "\(food.emoji) "

        if let warn3 = calendar.date(byAdding: .day, value: -3, to: expiry), warn3 > .now {
            var comps = calendar.dateComponents([.year, .month, .day], from: warn3)
            comps.hour = 9; comps.minute = 0
            schedule(
                id: "expiry3-\(food.id)",
                title: String(localized: "Food Expiring Soon"),
                body: "\(prefix)\(food.name) expires in 3 days. Use it before it's gone!",
                comps: comps
            )
        }

        if let warn1 = calendar.date(byAdding: .day, value: -1, to: expiry), warn1 > .now {
            var comps = calendar.dateComponents([.year, .month, .day], from: warn1)
            comps.hour = 9; comps.minute = 0
            schedule(
                id: "expiry1-\(food.id)",
                title: String(localized: "Last Chance!"),
                body: "\(prefix)\(food.name) expires tomorrow. Don't let it go to waste!",
                comps: comps
            )
        }
    }

    private func scheduleLowStockNotification(for food: FoodModel) {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) else { return }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        comps.hour = 9; comps.minute = 0
        let prefix = food.emoji.isEmpty ? "" : "\(food.emoji) "
        schedule(
            id: "stock-\(food.id)",
            title: String(localized: "Low Stock"),
            body: "\(prefix)\(food.name) is running low. Time to restock!",
            comps: comps
        )
    }

    private func schedule(id: String, title: String, body: String, comps: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }
}
