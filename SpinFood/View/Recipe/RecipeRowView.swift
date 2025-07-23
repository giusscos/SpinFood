//
//  RecipeRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct RecipeRowView: View {
    var recipe: RecipeModel
    
    var body: some View {
        VStack (alignment: .leading) {
            if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .clipShape(.rect(cornerRadius: 20))
            }
            
            Group {
                Text(recipe.name)
                    .font(.headline)
                
                Text(recipe.descriptionRecipe)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .padding(.leading, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 32))
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(.secondary.opacity(0.25), lineWidth: 1)
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 13))
}
