//
//  StatsView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query var recipes: [RecipeModel]
    @Query var food: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]
    @Query var refills: [FoodRefillModel]
    
    var cookedRecipes: [RecipeModel] {
        recipes.filter { $0.cookedAt.count > 0 }
    }
    
    var totalRecipeCooked: Int {
        var totalCooked: Int = 0
        for recipe in cookedRecipes {
            totalCooked += recipe.cookedAt.count
        }
        return totalCooked
    }
    
    var totalFoodEaten: Int {
        consumptions.count
    }
    
    var totalFoodRefilled: Int {
        refills.count
    }
    
    private func getMostCookedRecipe() -> RecipeModel? {
        return cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }.first
    }
    
    private func getMostConsumedFood() -> FoodModel? {
        let foodWithConsumptions = food.filter { ($0.consumptions?.count ?? 0) > 0 }
        let sorted = foodWithConsumptions.sorted { 
            ($0.consumptions?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0) > 
            ($1.consumptions?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0)
        }
        return sorted.first
    }
    
    private func getMostRefilledFood() -> FoodModel? {
        let foodWithRefills = food.filter { ($0.refills?.count ?? 0) > 0 }
        let sorted = foodWithRefills.sorted { 
            ($0.refills?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0) > 
            ($1.refills?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0)
        }
        return sorted.first
    }
    
    private func getTotalQuantity(for food: FoodModel) -> Decimal {
        (food.consumptions ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }
    
    private func getTotalRefilledQuantity(for food: FoodModel) -> Decimal {
        (food.refills ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if totalRecipeCooked > 0 || totalFoodEaten > 0 || totalFoodRefilled > 0 {
                        // Recipes cooked section
                        if totalRecipeCooked > 0 {
                            NavigationLink(destination: RecipeCookingStatsDetailView()) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Recipes cooked")
                                            .font(.headline)
                                            .foregroundStyle(.indigo)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let mostCooked = getMostCookedRecipe() {
                                        Text("\(mostCooked.name)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("\(mostCooked.cookedAt.count) times")
                                            .font(.title3)
                                            .foregroundStyle(.indigo)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("\(totalRecipeCooked)")
                                            .font(.title3)
                                            .foregroundStyle(.indigo)
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.indigo.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Food eaten section
                        if totalFoodEaten > 0 {
                            NavigationLink(destination: FoodConsumptionStatsDetailView()) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Food eaten")
                                            .font(.headline)
                                            .foregroundStyle(.purple)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let mostConsumed = getMostConsumedFood() {
                                        Text("\(mostConsumed.name)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("\(NSDecimalNumber(decimal: getTotalQuantity(for: mostConsumed)).doubleValue, specifier: "%.1f") \(mostConsumed.unit.abbreviation)")
                                            .font(.title3)
                                            .foregroundStyle(.purple)
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Food refilled section
                        if totalFoodRefilled > 0 {
                            NavigationLink(destination: FoodRefillStatsDetailView()) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Food refilled")
                                            .font(.headline)
                                            .foregroundStyle(.green)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let mostRefilled = getMostRefilledFood() {
                                        Text("\(mostRefilled.name)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("\(NSDecimalNumber(decimal: getTotalRefilledQuantity(for: mostRefilled)).doubleValue, specifier: "%.1f") \(mostRefilled.unit.abbreviation)")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        // No data view
                        VStack(spacing: 8) {
                            Image(systemName: "chart.pie")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No data to show")
                                .font(.headline)
                            Text("Start cooking recipes or adding food to see your statistics")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self, RecipeFoodModel.self], inMemory: true)
} 