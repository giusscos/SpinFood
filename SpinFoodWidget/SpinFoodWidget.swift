import WidgetKit
import SwiftUI

struct SpinFoodWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpinFoodWidgetEntry {
        SpinFoodWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (SpinFoodWidgetEntry) -> Void) {
        completion(SpinFoodWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpinFoodWidgetEntry>) -> Void) {
        let entry = SpinFoodWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SpinFoodWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SpinFoodWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SpinFoodWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            PantryAlertWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MealPlanWidgetView(snapshot: entry.snapshot)
        default:
            LargeWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Small: Pantry Alert

private struct PantryAlertWidgetView: View {
    var snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pantry", systemImage: "cabinet.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(snapshot.pantryAlertCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(snapshot.pantryAlertCount > 0 ? .orange : .primary)

            Text(snapshot.pantryAlertCount == 0 ? "All good" : "Need attention")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                miniStat(snapshot.expiringCount, "Expiring")
                miniStat(snapshot.lowStockCount, "Low")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func miniStat(_ value: Int, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium: Today's Meal Plan

private struct MealPlanWidgetView: View {
    var snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Today's Meals", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if snapshot.todayMeals.isEmpty {
                Spacer(minLength: 0)
                Text("No meals planned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(snapshot.todayMeals.prefix(3)) { meal in
                    HStack(spacing: 8) {
                        Image(systemName: meal.slotIcon)
                            .foregroundStyle(.orange)
                            .frame(width: 18)
                        Text(meal.slot)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text(meal.recipeName)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large: Combined

private struct LargeWidgetView: View {
    var snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Pantry Alerts", systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.pantryAlertCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("\(snapshot.expiringCount) expiring · \(snapshot.lowStockCount) low · \(snapshot.expiredCount) expired")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Quick Cook")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(snapshot.suggestedRecipeEmoji)
                        .font(.title)
                    Text(snapshot.suggestedRecipeName ?? "Open Foo")
                        .font(.caption.weight(.medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }

            Divider()

            Text("Today's Meals")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if snapshot.todayMeals.isEmpty {
                Text("No meals planned yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.todayMeals.prefix(4)) { meal in
                    HStack(spacing: 8) {
                        Image(systemName: meal.slotIcon)
                            .foregroundStyle(.orange)
                            .frame(width: 18)
                        Text(meal.slot)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text(meal.recipeName)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SpinFoodWidget: Widget {
    let kind: String = "SpinFoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpinFoodWidgetProvider()) { entry in
            SpinFoodWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Foo")
        .description("Pantry alerts, today's meal plan, and a quick cook suggestion.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    SpinFoodWidget()
} timeline: {
    SpinFoodWidgetEntry(date: .now, snapshot: .empty)
}
