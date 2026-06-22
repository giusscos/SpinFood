//
//  RecipeDetailsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeDetailSheet: Identifiable {
    case confirmEat
    case cookNow([StepRecipe])
    case steps([StepRecipe])

    var id: String {
        switch self {
            case .confirmEat:
                return "confirmEat"
            case .cookNow(let steps):
                return "cookNow-\(steps.count)"
            case .steps(let steps):
                return "steps-\(steps.count)"
        }
    }
}

private struct PolaroidImageView: View {
    let imageData: Data
    var rotation: Double = -1.5

    var body: some View {
        if let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 260, height: 220)
                .clipped()
                .padding(12)
                .padding(.bottom, 52)
                .background(.white)
                .clipShape(.rect(cornerRadius: 2))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .rotationEffect(.degrees(rotation))
        }
    }
}

struct RecipeDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var activeRecipeDetailSheet: ActiveRecipeDetailSheet?
    @State private var showDeleteConfirmation: Bool = false

    var recipe: RecipeModel
    var onEdit: () -> Void = {}

    var hasAllIngredients: Bool {
        recipe.missingIngredients.isEmpty
    }

    private var paperBackground: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Polaroid photo
                    if let imageData = recipe.image {
                        PolaroidImageView(imageData: imageData)
                            .padding(.top, 32)
                            .padding(.bottom, 16)
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [.orange.opacity(0.7), .red.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "fork.knife")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(width: 260, height: 220)
                        .padding(12)
                        .padding(.bottom, 52)
                        .background(.white)
                        .clipShape(.rect(cornerRadius: 2))
                        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                        .rotationEffect(.degrees(-1.5))
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    }

                    // Title block
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.largeTitle.bold())

                        if !recipe.descriptionRecipe.isEmpty {
                            Text(recipe.descriptionRecipe)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 20) {
                            if recipe.duration > 0 {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DURATION")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .tracking(0.5)
                                    Text(recipe.duration.formatted)
                                        .font(.callout.weight(.semibold))
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SERVINGS")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .tracking(0.5)
                                Text("\(recipe.servings)")
                                    .font(.callout.weight(.semibold))
                            }
                        }
                        .padding(.top, 4)
                    }
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    // Divider line — cookbook style
                    HStack {
                        Rectangle()
                            .fill(.secondary.opacity(0.25))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)

                    RecipeDetailsIngredientView(recipe: recipe, missingIngredients: recipe.missingIngredients)

                    RecipeDetailsStepView(recipe: recipe, activeRecipeDetailSheet: $activeRecipeDetailSheet)

                    RecipeDetailsCookButtonView(recipe: recipe, hasAllIngredients: hasAllIngredients, activeRecipeDetailSheet: $activeRecipeDetailSheet)
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .fullScreenCover(item: $activeRecipeDetailSheet) { sheet in
                switch sheet {
                    case .confirmEat:
                        RecipeConfirmEatView(recipe: recipe)
                    case .cookNow(let steps):
                        CookRecipeStepByStepView(recipe: recipe, steps: steps)
                    case .steps(let steps):
                        StepsSheetView(steps: steps)
                }
            }
            .navigationBarBackButtonHidden()
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26, *) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    } else {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Back", systemImage: "chevron.left.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .gray)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button {
                            handleEditButton()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    } else {
                        Button {
                            handleEditButton()
                        } label: {
                            Label("Edit", systemImage: "pencil.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .accent)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        .buttonStyle(.glassProminent)
                    } else {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .red)
                        }
                    }
                }
            }
            .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation, actions: {
                Button("Cancel", role: .cancel) { }
                Button("Delete Recipe", role: .destructive) {
                    deleteRecipe()
                }
            })
        }
    }

    func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }

    func handleEditButton() {
        onEdit()
    }
}

#Preview {
    RecipeDetailsView(recipe: RecipeModel(name: "Carbonara"))
}
