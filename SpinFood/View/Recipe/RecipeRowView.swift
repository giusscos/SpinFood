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
        if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 300)
            //                .mask(
            //                    LinearGradient(colors: [.black, .black, .black, .black, .clear, .clear], startPoint: .top, endPoint: .bottom)
            //                        .blur(radius: 16)
            //                )
//                .overlay(alignment: .bottom) {
//                    Text(recipe.name)
//                        .font(.title)
//                        .fontWeight(.semibold)
//                        .padding(.bottom, 24)
//                        .multilineTextAlignment(.center)
//                        .frame(maxWidth: .init(), alignment: .center)
//                }
        }
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 13))
}
