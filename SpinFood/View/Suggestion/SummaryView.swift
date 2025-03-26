//
//  SummaryView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData
import Charts

struct SummaryView: View {
    @Namespace private var namespace
    
    @State var store = Store()
    
    @State private var showStoreView: Bool = false
    
    @Query var recipes: [RecipeModel]
    
    @Query var food: [FoodModel]
    
    @Query var consumptions: [FoodConsumptionModel]
    
    @Query var refills: [FoodRefillModel]
    
    var filteredRecipes: [RecipeModel] {
        recipes.filter { recipe in
            guard let recipeIngredients = recipe.ingredients else { return false }
            
            return recipeIngredients.allSatisfy { recipeFood in
                guard let requiredIngredient = recipeFood.ingredient else { return false }
                guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                
                // If units are the same, direct comparison
                if requiredIngredient.unit == inventoryItem.unit {
                    return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
                }
                
                // Convert both quantities to grams for comparison when units differ
                let inventoryQuantityInGrams = inventoryItem.unit.convertToGrams(inventoryItem.currentQuantity)
                let neededQuantityInGrams = requiredIngredient.unit.convertToGrams(recipeFood.quantityNeeded)
                
                return inventoryQuantityInGrams >= neededQuantityInGrams
            }
        }
    }
    
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
    
    var body: some View {
        GeometryReader { geometry in
            if filteredRecipes.count == 0 && totalRecipeCooked == 0 && totalFoodEaten == 0 && totalFoodRefilled == 0 {
                ContentUnavailableView("No data to show", systemImage: "chart.pie", description: Text("Start cooking recipes or adding food to see your statistics and suggestions"))
            } else {
                ScrollView {
                    if filteredRecipes.count > 0 {
                        Section {
                            ScrollView(.horizontal) {
                                LazyHStack(spacing: 22) {
                                    ForEach(filteredRecipes) { recipe in
                                        NavigationLink {
                                            RecipeDetailsView(recipe: recipe)
                                                .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
                                        } label: {
                                            SummaryRowView(recipe: recipe, width: geometry.size.width)
                                                .matchedTransitionSource(id: recipe.id, in: namespace)
                                                .scrollTransition(
                                                    axis: .horizontal
                                                ) { content, phase in
                                                    content
                                                        .rotationEffect(.degrees(phase.value * 2.5))
                                                        .offset(y: phase.isIdentity ? 0 : 8)
                                                        .blur(radius: phase.isIdentity ? 0 : 4)
                                                }
                                                .containerRelativeFrame(.horizontal)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .scrollTargetLayout()
                                }
                            }
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.viewAligned)
                        } header: {
                            Text("Based on your ingredients")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    if totalRecipeCooked > 0 {
                        Section {
                            NavigationLink {
                                RecipeCookingStatsView()
                                    .navigationTransition(.zoom(sourceID: "recipeCookingChart", in: namespace))
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("Recipes cooked")
                                        .font(.headline)
                                        .foregroundStyle(.indigo)
                                    
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading) {
                                            if let mostCooked = getMostCookedRecipe() {
                                                Text("\(mostCooked.name)")
                                                    .font(.caption)
                                                    .tint(.secondary)
                                                    .lineLimit(1)
                                                
                                                Text("\(mostCooked.cookedAt.count) times")
                                                    .font(.title)
                                                    .tint(.indigo)
                                                    .fontWeight(.bold)
                                            } else {
                                                Text("\(totalRecipeCooked)")
                                                    .font(.title)
                                                    .tint(.indigo)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Chart(cookedRecipes) { value in
                                            BarMark(
                                                x: .value("Recipe", value.name),
                                                y: .value("Amount", value.cookedAt.count)
                                            )
                                            .foregroundStyle(by: .value("Asset", value.name))
                                            .cornerRadius(8)
                                        }
                                        .chartLegend(.hidden)
                                        .chartYAxis(.hidden)
                                        .chartXAxis(.hidden)
                                    }
                                }
                                .matchedTransitionSource(id: "recipeCookingChart", in: namespace)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if totalFoodEaten > 0 {
                        Section {
                            NavigationLink {
                                FoodConsumptionStatsView()
                                    .navigationTransition(.zoom(sourceID: "foodConsumptionChart", in: namespace))
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("Food eaten")
                                        .font(.headline)
                                        .foregroundStyle(.purple)
                                    
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading) {
                                            if let mostConsumed = getMostConsumedFood() {
                                                Text("\(mostConsumed.name)")
                                                    .font(.caption)
                                                    .tint(.secondary)
                                                    .lineLimit(1)
                                                
                                                Text("\(NSDecimalNumber(decimal: getTotalQuantity(for: mostConsumed)).doubleValue, specifier: "%.1f") \(mostConsumed.unit.abbreviation)")
                                                    .font(.title)
                                                    .tint(.purple)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Chart {
                                            ForEach(consumptions) { consumption in
                                                if let foodName = consumption.food?.name {
                                                    BarMark(
                                                        x: .value("Food", foodName),
                                                        y: .value("Amount", NSDecimalNumber(decimal: consumption.unit.convertToGrams(consumption.quantity)).doubleValue)
                                                    )
                                                    .foregroundStyle(by: .value("Asset", foodName))
                                                }
                                            }
                                        }
                                        .chartLegend(.hidden)
                                        .chartYAxis(.hidden)
                                        .chartXAxis(.hidden)
                                    }
                                }
                                .matchedTransitionSource(id: "foodConsumptionChart", in: namespace)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if totalFoodRefilled > 0 {
                        Section {
                            NavigationLink {
                                FoodRefillStatsView()
                                    .navigationTransition(.zoom(sourceID: "foodRefillChart", in: namespace))
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("Food refilled")
                                        .font(.headline)
                                        .foregroundStyle(.green)
                                    
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading) {
                                            if let mostRefilled = getMostRefilledFood() {
                                                Text("\(mostRefilled.name)")
                                                    .font(.caption)
                                                    .tint(.secondary)
                                                    .lineLimit(1)
                                                
                                                Text("\(NSDecimalNumber(decimal: getTotalRefilledQuantity(for: mostRefilled)).doubleValue, specifier: "%.1f") \(mostRefilled.unit.abbreviation)")
                                                    .font(.title)
                                                    .tint(.green)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Chart {
                                            ForEach(refills) { refill in
                                                if let foodName = refill.food?.name {
                                                    BarMark(
                                                        x: .value("Food", foodName),
                                                        y: .value("Amount", NSDecimalNumber(decimal: refill.unit.convertToGrams(refill.quantity)).doubleValue)
                                                    )
                                                    .foregroundStyle(by: .value("Asset", foodName))
                                                }
                                            }
                                        }
                                        .chartLegend(.hidden)
                                        .chartYAxis(.hidden)
                                        .chartXAxis(.hidden)
                                    }
                                }
                                .matchedTransitionSource(id: "foodRefillChart", in: namespace)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Summary")
            }
        }
    }
    
    private func getMostCookedRecipe() -> RecipeModel? {
        return cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }.first
    }
    
    private func getMostConsumedFood() -> FoodModel? {
        let foodWithQuantities = food.map { food in
            (
                food: food,
                totalGrams: food.totalConsumedQuantityInGrams
            )
        }
        
        return foodWithQuantities
            .filter { $0.totalGrams > 0 }
            .sorted { $0.totalGrams > $1.totalGrams }
            .first?.food
    }
    
    private func getMostRefilledFood() -> FoodModel? {
        let foodWithQuantities = food.map { food in
            (
                food: food,
                totalGrams: food.totalRefilledQuantityInGrams
            )
        }
        
        return foodWithQuantities
            .filter { $0.totalGrams > 0 }
            .sorted { $0.totalGrams > $1.totalGrams }
            .first?.food
    }
    
    private func getTotalQuantity(for food: FoodModel) -> Decimal {
        (food.consumptions ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }
    
    private func getTotalRefilledQuantity(for food: FoodModel) -> Decimal {
        (food.refills ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }
}

#Preview {
    SummaryView()
}
