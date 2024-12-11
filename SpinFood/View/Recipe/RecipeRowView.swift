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
            Text(recipe.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("\(recipe.duration)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }.padding(8)
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModal(name: "Carbonara", duration: 13))
}
