//
//  SummaryView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    enum ActiveSheet: Identifiable {
        case createRecipe
        case createFood

        var id: String {
            switch self {
            case .createRecipe: return "createRecipe"
            case .createFood:   return "createFood"
            }
        }
    }

    @Environment(Store.self) var store

    @State private var showPaywall: Bool = false
    @State private var activeSheet: ActiveSheet?

    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]
    @Query var refills: [FoodRefillModel]

    var cookedRecipes: [RecipeModel] {
        recipes.filter { $0.cookedAt.count > 0 }
    }

    var totalRecipeCooked: Int {
        cookedRecipes.reduce(0) { $0 + $1.cookedAt.count }
    }

    var totalFoodEaten: Int { consumptions.count }
    var totalFoodRefilled: Int { refills.count }

    var body: some View {
        Group {
            if store.hasActiveSubscription {
                subscriberContent
            } else {
                lockedContent
            }
        }
        .navigationTitle("Summary")
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createFood:   EditFoodView()
            case .createRecipe: EditRecipeView()
            }
        }
    }

    // MARK: - Subscriber content

    private var subscriberContent: some View {
        List {
            if totalRecipeCooked == 0 && totalFoodEaten == 0 && totalFoodRefilled == 0 {
                emptyDataState
            } else {
                TotalRecipeCookedWidgetView(totalRecipeCooked: totalRecipeCooked, cookedRecipes: cookedRecipes)
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                TotalFoodEatenWidgetView(totalFoodEaten: totalFoodEaten)
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                TotalFoodRefilledWidgetView(totalFoodRefilled: totalFoodRefilled)
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var emptyDataState: some View {
        if foods.isEmpty {
            VStack(spacing: 12) {
                Text("No ingredient found")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Insert ingredient to start creating recipes")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button { activeSheet = .createFood } label: { Text("Add") }
                    .tint(.accent)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } else if recipes.isEmpty {
            VStack(spacing: 12) {
                Text("No recipe found")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Insert recipe to start tracking your eating habits")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button { activeSheet = .createRecipe } label: { Text("Add") }
                    .tint(.accent)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            VStack(spacing: 8) {
                Text("No activity data yet")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Cook a recipe or log a meal to start tracking your habits")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Locked / upgrade content

    private var lockedContent: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.15), .yellow.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(spacing: 6) {
                    Text("Unlock Your Kitchen Insights")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)

                    Text("See how much you cook, track what you eat,\nand reduce food waste with detailed stats.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                StatPreviewRow(icon: "flame.fill",               color: .orange, text: "Recipes cooked over time")
                StatPreviewRow(icon: "fork.knife",               color: .green,  text: "Food consumption tracking")
                StatPreviewRow(icon: "bag.fill",                 color: .blue,   text: "Pantry refill history")
                StatPreviewRow(icon: "leaf.fill",                color: .teal,   text: "Food waste insights")
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Button {
                showPaywall = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.horizontal)

            Spacer()
        }
    }
}

struct StatPreviewRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(.system(.subheadline, design: .rounded))

            Spacer()

            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    SummaryView()
}
