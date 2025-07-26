//
//  StatsDataStructures.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import Foundation

// Data structures for charts
struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct RecipeCookingData: Identifiable {
    let id = UUID()
    let recipe: RecipeModel
    let dates: [Date]
}

struct DailyConsumptionData: Identifiable {
    let id = UUID()
    let date: Date
    let totalQuantity: Double
}

struct FoodConsumptionData: Identifiable {
    let id = UUID()
    let food: FoodModel
    let quantity: Decimal
    let dates: [Date]
}

struct DailyRefillData: Identifiable {
    let id = UUID()
    let date: Date
    let totalQuantity: Double
}

struct FoodRefillData: Identifiable {
    let id = UUID()
    let food: FoodModel
    let quantity: Decimal
    let dates: [Date]
} 