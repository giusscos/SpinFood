//
//  SuggestionRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/12/24.
//

import SwiftUI

struct SuggestionRowView: View {
    var recipe: RecipeModal
    
    var body: some View {
        Rectangle()
            .frame(minHeight: 75, maxHeight: 500)
            .aspectRatio(4/3, contentMode: .fit)
            .overlay(content: {
                if let imageData = recipe.image,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
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
                .background(LinearGradient(gradient: Gradient(colors: [Color.black, Color.clear]), startPoint: .bottom, endPoint: .top))
            })
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SuggestionRowView(recipe: RecipeModal(name: "Carbonara", ingredients: []))
}
