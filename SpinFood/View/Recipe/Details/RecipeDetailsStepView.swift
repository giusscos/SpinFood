//
//  RecipeDetailsStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

struct StepsSheetView: View {
    @Environment(\.dismiss) var dismiss

    var steps: [StepRecipe]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.accent)
                                    .frame(width: 32, height: 32)

                                Text("\(index + 1)")
                                    .font(.callout.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 8) {
                                if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 300 : 180)
                                        .clipShape(.rect(cornerRadius: 12))
                                }

                                Text(step.text)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RecipeDetailsStepView: View {
    var recipe: RecipeModel
    @Binding var activeRecipeDetailSheet: ActiveRecipeDetailSheet?

    var body: some View {
        if let steps = recipe.steps, !steps.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Method")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Text("\(steps.count) step\(steps.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(.capsule)
                }

                // First step preview
                if let firstStep = steps.first {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.accent)
                                .frame(width: 32, height: 32)

                            Text("1")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 8) {
                            if let imageData = firstStep.image, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 220 : 140)
                                    .clipShape(.rect(cornerRadius: 12))
                            }

                            Text(firstStep.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if steps.count > 1 {
                    Button {
                        activeRecipeDetailSheet = .steps(steps)
                    } label: {
                        Label("View all \(steps.count) steps", systemImage: "list.number")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(.accent)
                }
            }
            .padding()
        }
    }
}

#Preview {
    RecipeDetailsStepView(recipe: RecipeModel(name: "Carbonara"), activeRecipeDetailSheet: .constant(nil))
}
