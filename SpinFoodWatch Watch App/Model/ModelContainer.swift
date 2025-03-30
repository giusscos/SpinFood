//
//  ModelContainer.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            RecipeModel.self,
            FoodModel.self,
            RecipeFoodModel.self,
            FoodRefillModel.self,
            FoodConsumptionModel.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
} 