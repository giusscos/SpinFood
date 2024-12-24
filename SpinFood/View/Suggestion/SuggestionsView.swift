//
//  SuggestionsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Namespace private var namespace
    
    @State var store = Store()
    
    @State private var showStoreView: Bool = false
    
    @Query var recipes: [RecipeModal]
    
    @Query var food: [FoodModal]
    
    var filteredRecipes: [RecipeModal] {
        recipes.filter { recipe in
            guard let recipeIngredients = recipe.ingredients else { return false }
            
            return recipeIngredients.allSatisfy { recipeFood in
                guard let requiredIngredient = recipeFood.ingredient else { return false }
                guard let inventoryItem = food.first(where: { $0.id == requiredIngredient.id }) else { return false }
                
                return inventoryItem.currentQuantity >= recipeFood.quantityNeeded
            }
        }
    }
    
    var body: some View {
        if !store.purchasedSubscriptions.isEmpty {
            NavigationStack {
                List {
                    if filteredRecipes.count > 0 {
                        Section {
                            ForEach(filteredRecipes) { recipe in
                                NavigationLink {
                                    RecipeDetailsView(recipe: recipe)
                                        .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
                                } label: {
                                    SuggestionRowView(recipe: recipe)
                                        .matchedTransitionSource(id: recipe.id, in: namespace)
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                    } else {
                        ContentUnavailableView("No suggestions found", systemImage: "exclamationmark", description: Text("You can add ingredients by tapping on the Refill button in the Food section"))
                    }
                }
                .listStyle(.plain)
                .navigationTitle(filteredRecipes.count > 0 ? "Suggestions for you" : "No suggestions for now")
            }
        } else {
            Rectangle()
                .frame(minHeight: 75)
                .aspectRatio(4/3, contentMode: .fit)
                .foregroundStyle(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .topLeading, endPoint: .bottom))
                .overlay(content: {
                    VStack {
                        Text("Pro Access")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Unlock recipe suggestions and more 😋")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        
                        Button {
                            showStoreView.toggle()
                        } label: {
                            Label("Get it now", systemImage: "arrow.down")
                                .padding()
                                .background(Color.white)
                                .tint(Color.indigo)
                                .fontWeight(.bold)
                                .clipShape(Capsule())
                                .shadow(radius: 10, x: 0, y: 4)
                        }
                    }
                })
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                .sheet(isPresented: $showStoreView) {
                    StoreSubscriptionView()
                }
        }
    }
}

#Preview {
    SuggestionsView()
}
