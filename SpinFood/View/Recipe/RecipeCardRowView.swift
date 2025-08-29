//
//  RecipeCardRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 28/08/25.
//

import SwiftUI

struct RecipeCardRowView: View {
    var recipe: RecipeModel
    
    var size: CGSize
    
    var body: some View {
        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
            let image = Image(uiImage: uiImage)

            VStack(spacing: 0) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width * 0.9, height: size.height * 0.8)
                    .mask(
                        Rectangle()
                            .fill(
                                .linearGradient(colors: [
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(1),
                                    .black.opacity(0.7),
                                    .black.opacity(0.3),
                                    .black.opacity(0),
                                ], startPoint: .top, endPoint: .bottom)
                            )
                    )
                    .overlay (alignment: .bottom) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width * 1.1, height: size.height * 0.1)
                            .blur(radius: 64)
                            .offset(y: size.height * 0.125)
                            .scaleEffect(x: -1, y: 1)
                    }
                    .overlay (alignment: .bottom) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding()
                    }
            }
            .frame(width: size.width * 0.9, height: size.height * 0.8)
            .clipped()
            .clipShape(.rect(cornerRadius: 32))
        }
    }
}

#Preview {
    RecipeCardRowView(recipe: RecipeModel(name: "Carbonara"), size: CGSize(width: 320, height: 480))
}
