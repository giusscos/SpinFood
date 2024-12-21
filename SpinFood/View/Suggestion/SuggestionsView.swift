//
//  SuggestionsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Query var recipes: [RecipeModal]
    
    var body: some View {
        List {
            ForEach(recipes) { recipe in
                SuggestionRowView(recipe: recipe)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Suggestions for you")
    }
}

#Preview {
    SuggestionsView()
}
