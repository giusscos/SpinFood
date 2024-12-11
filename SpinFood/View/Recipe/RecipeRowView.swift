//
//  RecipeRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: RecipeModal
    
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text(recipe.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(recipe.descriptionRecipe)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                
            Text(recipe.duration.formatted)
                .font(.headline)
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModal(name: "Carbonara", duration: 13))
}
