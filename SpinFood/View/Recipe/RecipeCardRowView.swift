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
    
    var hideTitle: Bool = false
    
    var body: some View {
        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
            let image = Image(uiImage: uiImage)
        
            VStack {
                GeometryReader { geometry in
                    let itemSize = geometry.size
                    
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: itemSize.height * 0.9)
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
                    
                    Spacer()
                }
            }
            .frame(height: size.height * 0.7)
            .background {
                if !hideTitle {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width * 1.3, height: size.height * 1.3)
                        .blur(radius: 64)
                        .offset(y: size.height * 0.125)
                        .scaleEffect(x: -1, y: 1)
                }
            }
            .overlay (alignment: .bottom) {
                if !hideTitle {
                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    RecipeCardRowView(recipe: RecipeModel(name: "Carbonara"), size: CGSize(width: 320, height: 480))
}
