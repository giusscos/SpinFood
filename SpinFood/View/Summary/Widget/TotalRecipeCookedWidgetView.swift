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
    
    private let postItColor = Color(red: 1.0, green: 0.83, blue: 0.74)

    var body: some View {
        if totalRecipeCooked > 0 {
            NavigationLink {
                RecipeCookingStatsView()
                    .navigationTransition(.zoom(sourceID: recipeCookingTransitionId, in: namespace))
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recipes cooked")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.black.opacity(0.55))

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(totalRecipeCooked)")
                            .font(.system(size: 72, weight: .bold, design: .serif))
                            .foregroundStyle(.black.opacity(0.82))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("times cooked")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundStyle(.black.opacity(0.45))
                    }

                    Spacer()

                    if let mostCooked = getMostCookedRecipe() {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)

                            Text("\(mostCooked.name) · \(mostCooked.cookedAt.count)×")
                                .font(.system(.caption, design: .serif))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.black.opacity(0.38))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 260 : 220)
                .background {
                    ZStack(alignment: .top) {
                        postItColor
                        VStack(spacing: 22) {
                            ForEach(0..<8, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.055))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 48)
                    }
                }
                .clipShape(.rect(cornerRadius: 3))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.6))
                        .frame(width: 56, height: 16)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .offset(y: -8)
                }
                .rotationEffect(.degrees(-1.5))
                .padding(.vertical, 28)
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
