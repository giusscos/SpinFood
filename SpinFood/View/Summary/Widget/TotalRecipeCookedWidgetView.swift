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
                        
                        Spacer()
                        
                        VStack {
                            Spacer()
                            
                            Chart(cookedRecipes) { value in
                                SectorMark(
                                    angle: .value("Amount", value.cookedAt.count),
                                    innerRadius: .ratio(0.6)
                                )
                                .foregroundStyle(by: .value("Recipe", value.name))
                            }
                            .chartLegend(.hidden)
                            .chartYAxis(.hidden)
                            .chartXAxis(.hidden)
                        }
                    }
                    .matchedTransitionSource(id: recipeCookingTransitionId, in: namespace)
                }
            }
        }
    }
    
    private func getMostCookedRecipe() -> RecipeModel? {
        return cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }.first
    }
}

#Preview {
    TotalRecipeCookedWidgetView(totalRecipeCooked: 1, cookedRecipes: [RecipeModel(name: "Carbonara")])
}
