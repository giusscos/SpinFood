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
        if let imageData = recipe.image,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 500, alignment: .center)
                .overlay (alignment: .bottom) {
                    Color.clear
                    .background(.thinMaterial)
                    .frame(maxWidth: .infinity)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.black,  Color.clear, Color.clear, Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .overlay(alignment: .bottom) {
                        VStack (alignment: .leading) {
                            HStack {
                                Text(recipe.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(recipe.duration.formatted)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(recipe.descriptionRecipe)
                                .lineLimit(2)
                                .font(.subheadline)
                        }
                        .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModal(name: "Carbonara", duration: 13))
}
