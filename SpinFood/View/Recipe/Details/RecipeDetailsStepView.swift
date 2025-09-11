//
//  RecipeDetailsStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

struct RecipeDetailsStepView: View {
    var recipe: RecipeModel
    
    var body: some View {
        if let steps = recipe.steps, !steps.isEmpty {
            VStack (alignment: .leading) {
                HStack (alignment: .lastTextBaseline, spacing: 4) {
                    Group {
                        Text(steps.count == 1 ? "Step" : "Steps")
                        +
                        Text(":")
                    }
                    
                    Text(recipe.duration.formatted)
                        .foregroundStyle(.secondary)
                }
                .font(.headline)
                
                ForEach(steps) { step in
                    VStack(alignment: .leading, spacing: 8) {
                        if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 400 : 220)
                                .clipShape(.rect(cornerRadius: 20))
                        }
                        
                        Text(step.text)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
}
#Preview {
    RecipeDetailsStepView(recipe: RecipeModel(name: "Carbonara"))
}
