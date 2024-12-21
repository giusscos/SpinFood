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
    
    @Query var recipes: [RecipeModal]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(recipes) { recipe in
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
            .listStyle(.plain)
            .navigationTitle("Suggestions for you")
        }
    }
}

#Preview {
    SuggestionsView()
}
