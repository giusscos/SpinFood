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
                case .createRecipe:
                    return "createRecipe"
                case .createFood:
                    return "createFood"
            }
        }
    }
    
    @State private var showStoreView: Bool = false
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
        List {
            if totalRecipeCooked == 0 && totalFoodEaten == 0 && totalFoodRefilled == 0 {
                if foods.isEmpty {
                    VStack {
                        Text("No ingredient found 😕")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Insert ingredient to start create recipes")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            activeSheet = .createFood
                        } label: {
                            Text("Add")
                        }
                        .tint(.accent)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if recipes.isEmpty {
                    VStack {
                        Text("No recipe found 😕")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Insert recipe to start track your eating habits")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            activeSheet = .createRecipe
                        } label: {
                            Text("Add")
                        }
                        .tint(.accent)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack {
                        Text("No eat or refill data found 😕")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Click on your favorite recipe, click the \"cook\" or \"eat\" button to start track your eating habits")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                TotalRecipeCookedWidgetView(totalRecipeCooked: totalRecipeCooked, cookedRecipes: cookedRecipes)
                
                TotalFoodEatenWidgetView(totalFoodEaten: totalFoodEaten)
                
                TotalFoodRefilledWidgetView(totalFoodRefilled: totalFoodRefilled)
            }
        }
        .navigationTitle("Summary")
        .sheet(item: $activeSheet, content: { sheet in
            switch sheet {
                case .createFood:
                    EditFoodView()
                case .createRecipe:
                    EditRecipeView()
            }
        })
    }
}

#Preview {
    SummaryView()
}
