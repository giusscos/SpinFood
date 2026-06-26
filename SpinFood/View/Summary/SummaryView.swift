//
//  SummaryView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(Store.self) var store

    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]
    @Query var refills: [FoodRefillModel]

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
        })
    }

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Summary")
                    .font(.system(.title3, design: .serif).weight(.semibold))
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
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private var emptyDataState: some View {
        if foods.isEmpty {
            EmptyStateView(
                symbol: "cabinet",
                title: "No Ingredients",
                subtitle: "Add your first ingredient to start creating recipes"
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else if recipes.isEmpty {
            EmptyStateView(
                symbol: "book",
                title: "No Recipes",
                subtitle: "Add a recipe to start tracking your cooking habits"
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            EmptyStateView(
                symbol: "chart.bar.xaxis",
                title: "No Activity Yet",
                subtitle: "Cook a recipe or log a meal to start tracking your habits"
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Locked / upgrade content

    private var lockedContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Kitchen Stats")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .tracking(3)

                    Text("Premium Feature")
                        .font(.system(size: 11, weight: .regular, design: .serif))
                        .foregroundStyle(.secondary)
                        .tracking(3)
                        .textCase(.uppercase)
                }
                .padding(.top, 40)

                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange.opacity(0.85))

                VStack(spacing: 24) {
                    tocEntry(roman: "I",   title: "Recipes Cooked",      note: "Track every meal over time")
                    tocDivider
                    tocEntry(roman: "II",  title: "Food Consumption",    note: "Log what you eat")
                    tocDivider
                    tocEntry(roman: "III", title: "Pantry Refills",      note: "History of every restock")
                    tocDivider
                    tocEntry(roman: "IV",  title: "Food Waste Insights", note: "Reduce waste, save money")
                }

                Spacer(minLength: 60)
            }
            .padding(.horizontal)
        }
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
    }

    private func tocEntry(roman: String, title: String, note: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(roman)
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.body, design: .serif))

                Text(note)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(". . . . . . .")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .padding(.vertical, 11)
    }

    private var tocDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 0.5)
    }
}

#Preview {
    SummaryView()
}
