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
                .overlay(alignment: .bottom, content: {
                    Color.clear
                        .background(.thinMaterial)
                        .frame(maxWidth: .infinity)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.black, .black, .clear]),
                                startPoint: .bottom,
                                endPoint: .center
                            )
                        )
                })
                .overlay(alignment: .bottom, content: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.title)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .shadow(radius: 6, x: 0, y: 4)
                        
                        ScrollView (.horizontal) {
                            HStack {
                                if let ingredients = recipe.ingredients {
                                    ForEach(ingredients) { ingredient in
                                        if let ingredient = ingredient.ingredient {
                                            Text("\(ingredient.name)")
                                                .padding(.vertical, 8)
                                                .padding(.horizontal)
                                                .foregroundStyle(.white)
                                                .shadow(radius: 6, x: 0, y: 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding(8)
                })
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    SummaryRowView(recipe: RecipeModel(name: "Carbonara", ingredients: []), width: 300)
}
