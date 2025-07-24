//
//  TotalRecipeCookedWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import Charts
import SwiftUI

struct TotalRecipeCookedWidgetView: View {
    @Namespace private var namespace
    
    let recipeCookingTransitionId: String = "recipeCookingChart"

    var totalRecipeCooked: Int
    var cookedRecipes: [RecipeModel]
    
    var body: some View {
        if totalRecipeCooked > 0 {
            Section {
                NavigationLink {
                    RecipeCookingStatsView()
                        .navigationTransition(.zoom(sourceID: recipeCookingTransitionId, in: namespace))
                } label: {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Recipes cooked")
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            
                            VStack(alignment: .leading) {
                                if let mostCooked = getMostCookedRecipe() {
                                    Text("\(mostCooked.cookedAt.count) times")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(mostCooked.name)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                } else {
                                    Text("\(totalRecipeCooked)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Chart(cookedRecipes) { value in
                            BarMark(
                                x: .value("Recipe", value.name),
                                y: .value("Amount", value.cookedAt.count),
                            )
                            .foregroundStyle(by: .value("Recipe", value.name))
                            .cornerRadius(16)
                        }
                        .chartLegend(.hidden)
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                        .padding(.top, 32)
                    }
                    .matchedTransitionSource(id: recipeCookingTransitionId, in: namespace)
                }
            }
            .listRowInsets(.init(top: 16, leading: 16, bottom: 0, trailing: 16))
        }
    }
    
    private func getMostCookedRecipe() -> RecipeModel? {
        return cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }.first
    }
}

#Preview {
    TotalRecipeCookedWidgetView(totalRecipeCooked: 1, cookedRecipes: [RecipeModel(name: "Carbonara")])
}
