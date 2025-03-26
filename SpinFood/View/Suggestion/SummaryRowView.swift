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
        if let imageData = recipe.image,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: width)
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
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    SummaryRowView(recipe: RecipeModel(name: "Carbonara", ingredients: []), width: 300)
}
