//
//  SummaryRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/12/24.
//

import SwiftUI

struct SummaryRowView: View {
    var recipe: RecipeModel
    var width: CGFloat?
    
    var body: some View {
        RecipeImageView(recipe: recipe, width: width, cornerRadius: 16)
    }
}

#Preview {
    SummaryRowView(recipe: RecipeModel(name: "Carbonara", ingredients: []), width: 300)
}
