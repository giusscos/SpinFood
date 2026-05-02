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
        NavigationLink {
            RecipeDetailsView(recipe: recipe, onEdit: {
                activeRecipeSheet = nil
                activeRecipeSheet = .edit(recipe)
            })
            .navigationTransition(.zoom(sourceID: recipe.id, in: namespace))
        } label: {
            VStack(spacing: 0) {
                Group {
                    if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [.orange.opacity(0.7), .red.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 280 : 200)
                .clipped()
                .padding(.top, 12)
                .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.black)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        if recipe.duration > 0 {
                            Label(recipe.duration.formatted, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }

                        Label("\(recipe.servings)", systemImage: "person.2")
                            .font(.caption)
                            .foregroundStyle(Color.gray)

                        Spacer()

                        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            let missingCount = recipe.missingIngredients.count
                            if missingCount == 0 {
                                Label("Ready", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.green.opacity(0.25))
                                    .clipShape(.capsule)
                            } else {
                                Label("\(missingCount) missing", systemImage: "exclamationmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.orange.opacity(0.25))
                                    .clipShape(.capsule)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.white)
            .clipShape(.rect(cornerRadius: 2))
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
            .rotationEffect(.degrees(-1.5))
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .matchedTransitionSource(id: recipe.id, in: namespace)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecipeRowView(recipe: RecipeModel(name: "Carbonara", duration: 780), activeRecipeSheet: .constant(nil))
}
