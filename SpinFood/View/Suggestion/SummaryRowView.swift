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
    var heigth: CGFloat?
    
    var body: some View {
        RecipeImageView(recipe: recipe, width: width, height: heigth, cornerRadius: 16)
    }
}

#Preview {
    SummaryRowView(recipe: RecipeModel(name: "Carbonara", ingredients: []))
}
