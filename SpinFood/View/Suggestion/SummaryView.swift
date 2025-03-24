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
    
    var filteredRecipes: [RecipeModel] {
        recipes.filter { recipe in
            guard let recipeIngredients = recipe.ingredients else { return false }
            
            return recipeIngredients.allSatisfy { recipeFood in
                guard let requiredIngredient = recipeFood.ingredient else { return false }
                guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                
                return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
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
    
    var body: some View {
        GeometryReader { geometry in
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
                                            .frame(width: geometry.size.width)
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
                                    .listRowSeparator(.hidden)
                                }
                                .scrollTargetLayout()
                            }
                        }
                        .scrollIndicators(.hidden)
                        .scrollTargetBehavior(.viewAligned)
                    }
                    .padding(.vertical)
                } else {
                    ContentUnavailableView("No suggestions found", systemImage: "exclamationmark", description: Text("You can add ingredients by tapping on the Refill button in the Food section"))
                        .listRowSeparator(.hidden)
                }
                
                if totalRecipeCooked > 0 {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Recipe cooked")
                                .font(.headline)
                                .foregroundStyle(.indigo)
                            
                            HStack(alignment: .bottom) {
                                Text("\(totalRecipeCooked)")
                                    .font(.title)
                                    .fontWeight(.bold)
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
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle(filteredRecipes.count > 0 ? "Suggestions for you" : "")
        }
    }
}

#Preview {
    SummaryView()
}
