//
//  TotalRecipeCookedWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import SwiftUI

struct TotalRecipeCookedWidgetView: View {
    @Namespace private var namespace
    
    let recipeCookingTransitionId: String = "recipeCookingChart"

    var totalRecipeCooked: Int
    var cookedRecipes: [RecipeModel]
    
    var body: some View {
        if totalRecipeCooked > 0 {
            NavigationLink {
                RecipeCookingStatsView()
                    .navigationTransition(.zoom(sourceID: recipeCookingTransitionId, in: namespace))
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recipes cooked")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(totalRecipeCooked)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("times cooked")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer()

                    if let mostCooked = getMostCookedRecipe() {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)

                            Text("\(mostCooked.name) · \(mostCooked.cookedAt.count)×")
                                .font(.system(.caption, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 260 : 220)
                .background(
                    LinearGradient(
                        colors: [.orange, .red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(.rect(cornerRadius: 4))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .rotationEffect(.degrees(-1.5))
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .matchedTransitionSource(id: recipeCookingTransitionId, in: namespace)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func getMostCookedRecipe() -> RecipeModel? {
        cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }.first
    }
}

#Preview {
    TotalRecipeCookedWidgetView(totalRecipeCooked: 12, cookedRecipes: [RecipeModel(name: "Carbonara")])
}
