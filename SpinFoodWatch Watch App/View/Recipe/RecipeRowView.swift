//
//  RecipeRowView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 26/07/25.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: RecipeModel
    
    var body: some View {
        if let imageData = recipe.image,
           let uiImage = UIImage(data: imageData) {
            VStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 127)
                    .clipShape(.rect(cornerRadius: 16))
                
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara"))
}
