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
        if let imageData = recipe.image,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 200)
                .overlay (alignment: .bottom) {
                    Color.clear
                    .background(.thinMaterial)
                    .frame(maxWidth: .infinity)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [.black, .black, .clear, .clear, .clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .overlay(alignment: .bottom) {
                        VStack (alignment: .leading) {
                            Text(recipe.duration.formatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(recipe.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(recipe.descriptionRecipe)
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tint(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 13))
}
