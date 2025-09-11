//
//  RecipeRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI

struct RecipeRowView: View {
    @Namespace var namespace
    
    var recipe: RecipeModel
    
    @Binding var activeRecipeSheet: ActiveRecipeSheet?
    
    var body: some View {
        VStack (alignment: .leading) {
            if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 450 : 300)
                    .clipShape(.rect(cornerRadius: 6))
            }
            
            NavigationLink {
                RecipeDetailsView(recipe: recipe, onEdit: {
                    activeRecipeSheet = nil
                    
                    activeRecipeSheet = .edit(recipe)
                })
                .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
            } label: {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if recipe.descriptionRecipe != "" {
                        Text(recipe.descriptionRecipe)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .matchedTransitionSource(id: recipe.id, in: namespace)
        .padding(.vertical, 6)
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 13), activeRecipeSheet: .constant(nil))
}
