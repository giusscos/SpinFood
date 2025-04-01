//
//  RecipeRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: RecipeModel
    var height: CGFloat?
    
    var body: some View {
        RecipeImageView(recipe: recipe, height: height)
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 13))
}
