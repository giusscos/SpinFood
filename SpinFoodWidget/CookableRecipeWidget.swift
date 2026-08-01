import WidgetKit
import SwiftUI
import UIKit
import AppIntents

struct CookableRecipeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CookableRecipeWidgetEntry {
        CookableRecipeWidgetEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CookableRecipeWidgetEntry) -> Void) {
        completion(CookableRecipeWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CookableRecipeWidgetEntry>) -> Void) {
        let entry = CookableRecipeWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct CookableRecipeWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

private extension WidgetSnapshot {
    static let placeholder = WidgetSnapshot(
        pantryAlertCount: 0,
        expiringCount: 0,
        lowStockCount: 0,
        expiredCount: 0,
        todayMeals: [],
        suggestedRecipeName: nil,
        suggestedRecipeEmoji: "🍽️",
        cookableRecipes: [
            WidgetCookableRecipe(
                id: "placeholder",
                name: "Tofu Vegetable Stir-Fry",
                durationText: "20 mins",
                ingredientCount: 6,
                imageJPEG: nil
            ),
            WidgetCookableRecipe(
                id: "placeholder-2",
                name: "Pasta Primavera",
                durationText: "30 mins",
                ingredientCount: 8,
                imageJPEG: nil
            )
        ],
        selectedCookableRecipeID: "placeholder",
        updatedAt: .now
    )
}

struct CookableRecipeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: CookableRecipeWidgetEntry

    var body: some View {
        CookableRecipeWidgetLayout(
            snapshot: entry.snapshot,
            isCompact: family == .systemSmall
        )
    }
}

// MARK: - Layout

private enum CookWidgetStyle {
    /// Same paper tone as recipe details (`BookRecipePage`).
    static let background = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1)
        }
    )
    static let ink = Color(red: 0.22, green: 0.36, blue: 0.28)
    static let inkMuted = Color(red: 0.22, green: 0.36, blue: 0.28).opacity(0.7)
}

private struct CookableRecipeWidgetLayout: View {
    var snapshot: WidgetSnapshot
    var isCompact: Bool

    private var recipe: WidgetCookableRecipe? { snapshot.selectedCookableRecipe }
    private var canCycle: Bool { snapshot.cookableRecipes.count > 1 }

    var body: some View {
        Group {
            if let recipe {
                recipeContent(recipe)
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(CookWidgetStyle.background, for: .widget)
    }

    @ViewBuilder
    private func recipeContent(_ recipe: WidgetCookableRecipe) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                polaroidImage(recipe, size: isCompact ? CGSize(width: 58, height: 46) : CGSize(width: 78, height: 60))
                Spacer(minLength: 8)
                if canCycle {
                    Button(intent: NextCookableRecipeIntent()) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: isCompact ? 13 : 15, weight: .semibold))
                            .foregroundStyle(CookWidgetStyle.ink)
                            .frame(width: isCompact ? 30 : 34, height: isCompact ? 30 : 34)
                            .background(CookWidgetStyle.ink.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
                    Text(recipe.name)
                        .font(.system(size: isCompact ? 14 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(CookWidgetStyle.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(metaLine(for: recipe))
                        .font(.system(size: isCompact ? 11 : 13, weight: .medium, design: .rounded))
                        .foregroundStyle(CookWidgetStyle.inkMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(intent: StartCookFromWidgetIntent(recipeID: recipe.id)) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: isCompact ? 14 : 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: isCompact ? 34 : 40, height: isCompact ? 34 : 40)
                        .background(CookWidgetStyle.ink, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "frying.pan")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(CookWidgetStyle.ink.opacity(0.45))

            Spacer(minLength: 0)

            Text("Nothing ready to cook")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(CookWidgetStyle.ink)

            Text("Stock your pantry to unlock recipes.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(CookWidgetStyle.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
    }

    private func metaLine(for recipe: WidgetCookableRecipe) -> String {
        let ingredients = "\(recipe.ingredientCount) ingredient\(recipe.ingredientCount == 1 ? "" : "s")"
        if recipe.durationText.isEmpty || recipe.durationText == "0 mins" {
            return ingredients
        }
        return "\(recipe.durationText) • \(ingredients)"
    }

    @ViewBuilder
    private func polaroidImage(_ recipe: WidgetCookableRecipe, size: CGSize) -> some View {
        Group {
            if let data = recipe.imageJPEG, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                ZStack {
                    Color(UIColor.secondarySystemFill)
                    Image(systemName: "fork.knife")
                        .font(.system(size: isCompact ? 16 : 20))
                        .foregroundStyle(.secondary)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .padding(isCompact ? 4 : 5)
        .background(.white)
        .shadow(color: .black.opacity(0.16), radius: 5, x: 0.5, y: 2)
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(.white.opacity(0.7))
                .frame(width: isCompact ? 22 : 28, height: isCompact ? 7 : 8)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                .offset(y: isCompact ? -4 : -5)
        }
        .rotationEffect(.degrees(-1.2))
    }
}

struct CookableRecipeWidget: Widget {
    let kind: String = "CookableRecipeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CookableRecipeWidgetProvider()) { entry in
            CookableRecipeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ready to Cook")
        .description("A recipe you can cook right now with what's in your pantry.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    CookableRecipeWidget()
} timeline: {
    CookableRecipeWidgetEntry(date: .now, snapshot: .placeholder)
}

#Preview(as: .systemMedium) {
    CookableRecipeWidget()
} timeline: {
    CookableRecipeWidgetEntry(date: .now, snapshot: .placeholder)
}
