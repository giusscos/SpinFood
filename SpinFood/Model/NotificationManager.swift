import Foundation
import UserNotifications

/// When the daily reminder goes out, in minutes after midnight.
enum ReminderSchedule {
    static let storageKey = "reminder_minutes"
    static let off = -1
    static let morning = 9 * 60
    static let beforeDinner = 17 * 60
}

/// Where tapping a reminder takes the person.
enum ReminderRoute: Equatable {
    case recipeIdeas
    case recipeIdea(String)
    case bookRecipe(UUID)
    case inventory
    case quickAdd

    var rawValue: String {
        switch self {
        case .recipeIdeas: return "ideas"
        case .recipeIdea(let id): return "idea:\(id)"
        case .bookRecipe(let id): return "book:\(id.uuidString)"
        case .inventory: return "inventory"
        case .quickAdd: return "quick_add"
        }
    }

    init?(rawValue: String) {
        if rawValue == "ideas" {
            self = .recipeIdeas
        } else if rawValue.hasPrefix("idea:") {
            self = .recipeIdea(String(rawValue.dropFirst("idea:".count)))
        } else if rawValue.hasPrefix("book:"), let id = UUID(uuidString: String(rawValue.dropFirst("book:".count))) {
            self = .bookRecipe(id)
        } else if rawValue == "inventory" {
            self = .inventory
        } else if rawValue == "quick_add" {
            self = .quickAdd
        } else {
            return nil
        }
    }
}

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private static let routeKey = "foo_route"
    private static let reminderPrefix = "reminder-"
    /// Identifiers from versions that sent one alert per food. The cook timer's alert isn't ours to touch.
    private static let legacyPrefixes = ["expiry3-", "expiry1-", "stock-"]

    /// The screen a tapped reminder asked for, until `ContentView` takes it.
    var pendingRoute: ReminderRoute?
    /// Bumped when the reminders need rebuilding outside the app's usual moments, like a changed setting.
    private(set) var rescheduleRequests = 0
    /// Runs one at a time: an overlapping run could read the pending list too early and leave a stale reminder.
    @ObservationIgnored private var lastUpdate: Task<Void, Never>?

    private override init() {
        super.init()
    }

    /// Call at launch: a tap that launches the app is delivered right away.
    func startHandlingTaps() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let rawRoute = response.notification.request.content.userInfo[Self.routeKey] as? String
        DispatchQueue.main.async {
            if let route = rawRoute.flatMap(ReminderRoute.init(rawValue:)) {
                self.pendingRoute = route
            }
            completionHandler()
        }
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestReschedule() {
        rescheduleRequests += 1
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Replaces the planned reminders with ones based on the kitchen right now.
    func reschedule(
        foods: [FoodModel],
        recipes: [RecipeModel],
        savedRecords: [FoodConsumptionModel],
        wasteRecords: [FoodWasteModel]
    ) {
        let minutes = UserDefaults.standard.object(forKey: ReminderSchedule.storageKey) as? Int
            ?? ReminderSchedule.beforeDinner
        let plan = ReminderPlanner.plan(
            foods: foods,
            recipes: recipes,
            savedRecords: savedRecords,
            wasteRecords: wasteRecords,
            minutes: minutes
        )
        let previous = lastUpdate
        lastUpdate = Task {
            await previous?.value
            await apply(plan)
        }
    }

    private func apply(_ plan: [PlannedReminder]) async {
        let center = UNUserNotificationCenter.current()
        let prefixes = Self.legacyPrefixes + [Self.reminderPrefix]
        let stale = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { identifier in prefixes.contains { identifier.hasPrefix($0) } }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        for reminder in plan {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.threadIdentifier = "reminders"
            content.userInfo = [Self.routeKey: reminder.route.rawValue]
            content.badge = reminder.badge.map(NSNumber.init(value:))
            let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.fireDate, repeats: false)
            try? await center.add(UNNotificationRequest(
                identifier: Self.reminderPrefix + reminder.dayKey,
                content: content,
                trigger: trigger
            ))
        }
    }
}

// MARK: - Planning

struct PlannedReminder {
    let dayKey: String
    let fireDate: DateComponents
    let title: String
    let body: String
    let route: ReminderRoute
    var badge: Int? = nil
}

/// Decides what each day's single reminder says. Rebuilt every time the app opens or closes, so a
/// reminder never describes a kitchen that has changed.
///
/// Reminders only work while people leave them on, so this errs towards fewer:
/// - Food due today always gets its reminder. A two-day heads-up waits if there was one yesterday,
///   since that food still gets its reminder on the day.
/// - "Used or thrown away?" goes out at most weekly; the inventory asks about expired food anyway.
/// - Everything else needs a quiet day with nothing around it.
/// - Nothing is planned beyond two weeks, so reminders stop for anyone who has stopped opening the app.
enum ReminderPlanner {
    private static let horizonDays = 14
    private static let comebackDelays = [3, 10]
    private static let daysBetweenExpiredQuestions = 7
    private static let namesInTitle = 3
    private static let saturdayWeekday = 7
    private static let sundayWeekday = 1

    static func plan(
        foods: [FoodModel],
        recipes: [RecipeModel],
        savedRecords: [FoodConsumptionModel],
        wasteRecords: [FoodWasteModel],
        minutes: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PlannedReminder] {
        guard minutes >= 0 else { return [] }

        let hour = minutes / 60
        let minute = minutes % 60
        let today = calendar.startOfDay(for: now)
        let days: [Date] = (0..<horizonDays).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { return nil }
            return day
        }

        var byDay: [Date: PlannedReminder] = [:]
        func fill(_ day: Date, title: String, body: String, route: ReminderRoute, badge: Int? = nil) {
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = hour
            components.minute = minute
            byDay[day] = PlannedReminder(
                dayKey: String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0),
                fireDate: components,
                title: title,
                body: body,
                route: route,
                badge: badge
            )
        }
        func neighbor(of day: Date, by offset: Int) -> Date? {
            calendar.date(byAdding: .day, value: offset, to: day)
        }
        func hasReminder(_ day: Date?) -> Bool {
            day.map { byDay[$0] != nil } ?? false
        }
        func isFree(_ day: Date) -> Bool { byDay[day] == nil }
        func isQuiet(_ day: Date) -> Bool {
            isFree(day) && !hasReminder(neighbor(of: day, by: -1)) && !hasReminder(neighbor(of: day, by: 1))
        }

        let dated = foods.filter { !$0.isOutOfStock && $0.expiryDate != nil }
        func daysLeft(_ food: FoodModel, from day: Date) -> Int? {
            food.expiryDate.flatMap { calendar.dateComponents([.day], from: day, to: calendar.startOfDay(for: $0)).day }
        }
        let candidates = CookSuggestion.candidates(foods: foods, recipes: recipes, now: now)

        // Food about to expire comes first: nothing else can take its place.
        for day in days {
            let dueToday = dated.filter { daysLeft($0, from: day) == 0 }
            var dueSoon = dated.filter { daysLeft($0, from: day) == 2 }
            if dueToday.isEmpty && hasReminder(neighbor(of: day, by: -1)) {
                dueSoon = []
            }
            let due = dueToday + dueSoon
            guard !due.isEmpty else { continue }

            let suggestion = CookSuggestion.best(using: due, in: candidates)
            fill(
                day,
                title: useSoonTitle(today: dueToday, soon: dueSoon),
                body: suggestion.map { String(localized: "Recipe idea: \($0.name)") }
                    ?? String(localized: "Tap to see what you can cook."),
                route: suggestion?.route ?? .recipeIdeas,
                badge: due.count
            )
        }

        // The day after, ask what happened, but not if tomorrow already has something to say.
        var lastQuestion: Date?
        for day in days where isFree(day) && !hasReminder(neighbor(of: day, by: 1)) {
            let overdue = dated.filter { daysLeft($0, from: day) == -1 }
            guard !overdue.isEmpty else { continue }
            if let lastQuestion,
               let gap = calendar.dateComponents([.day], from: lastQuestion, to: day).day,
               gap < daysBetweenExpiredQuestions {
                continue
            }
            lastQuestion = day
            fill(
                day,
                title: String(localized: "Used or thrown away? \(names(of: overdue))"),
                body: String(localized: "Tap to log it and keep your kitchen up to date."),
                route: .inventory
            )
        }

        // The week in review, when there's anything to review. It can wait a day or two for a free slot.
        let nextWeek = days.prefix(8)
        if let sunday = nextWeek.first(where: { calendar.component(.weekday, from: $0) == sundayWeekday }),
           let weekStart = calendar.date(byAdding: .day, value: -7, to: sunday) {
            let week = DateInterval(start: weekStart, end: sunday)
            let saved = savedRecords.filter { week.contains($0.consumedAt) }.count
            let wasted = wasteRecords.estimatedGrams(in: week)
            let slots = (0...2).compactMap { neighbor(of: sunday, by: $0) }.filter { days.contains($0) }
            if saved > 0 || wasted > 0, let day = slots.first(where: isFree) {
                fill(
                    day,
                    title: String(localized: "Your week in the kitchen"),
                    body: recapBody(saved: saved, wastedGrams: wasted),
                    route: .inventory
                )
            }
        }

        // Running low: Saturdays only, ahead of the weekly shop, so it can't nag every day.
        let lowStock = foods.filter(\.isLowStock)
        if !lowStock.isEmpty,
           let day = nextWeek.first(where: { calendar.component(.weekday, from: $0) == saturdayWeekday }),
           isQuiet(day) {
            fill(
                day,
                title: String(localized: "Running low: \(names(of: lowStock))"),
                body: String(localized: "Tap to see what to restock."),
                route: .inventory
            )
        }

        // A nudge for anyone who has stopped opening the app. Opening it pushes these back, so regulars never see them.
        for (index, delay) in comebackDelays.enumerated() {
            let window = days.filter { day in
                guard let offset = calendar.dateComponents([.day], from: today, to: day).day else { return false }
                return (delay...(delay + 2)).contains(offset)
            }
            guard let day = window.first(where: isQuiet) else { continue }
            if index == 0 {
                fill(
                    day,
                    title: String(localized: "Been shopping?"),
                    body: String(localized: "Add what you bought in a few taps."),
                    route: .quickAdd
                )
            } else {
                fill(
                    day,
                    title: String(localized: "What's in your kitchen?"),
                    body: String(localized: "Foo can only remind you about food it knows about."),
                    route: .quickAdd
                )
            }
        }

        return byDay.keys.sorted().compactMap { byDay[$0] }
    }

    private static func useSoonTitle(today: [FoodModel], soon: [FoodModel]) -> String {
        let foods = today + soon
        guard foods.count <= namesInTitle else {
            return String(localized: "Use soon: \(foods.count) foods")
        }
        let listed = names(of: foods)
        if soon.isEmpty { return String(localized: "Use today: \(listed)") }
        if today.isEmpty { return String(localized: "Use within 2 days: \(listed)") }
        return String(localized: "Use soon: \(listed)")
    }

    private static func names(of foods: [FoodModel]) -> String {
        foods.prefix(namesInTitle).map(\.name).formatted(.list(type: .and))
    }

    private static func recapBody(saved: Int, wastedGrams: Double) -> String {
        if wastedGrams <= 0 {
            return String(localized: "Foods saved: \(saved). Nothing thrown away. Well done!")
        }
        let wasted = wastedGrams.wasteWeightText
        if saved == 0 {
            return String(localized: "Thrown away: \(wasted). Tap to see what to use first.")
        }
        return String(localized: "Foods saved: \(saved) · Thrown away: \(wasted)")
    }
}
