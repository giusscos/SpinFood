//
//  RecipeDetailsStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

// MARK: - Shared step preview card (used in details + edit views)

struct StepPreviewCard: View {
    var step: StepRecipe
    var index: Int

    private var previewText: String {
        if let block = step.sortedBlocks.first(where: { $0.type == .text }) {
            return block.textContent
        }
        return step.text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step \(index)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(previewText.isEmpty ? "Empty" : previewText)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(previewText.isEmpty ? .tertiary : .primary)
            let count = step.sortedBlocks.count
            if count > 0 {
                Label("\(count) block\(count == 1 ? "" : "s")", systemImage: "square.stack")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .frame(width: 110, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.07), in: .rect(cornerRadius: 10))
    }
}

// MARK: - Steps section in recipe details

struct RecipeDetailsStepView: View {
    var recipe: RecipeModel
    @Binding var activeRecipeDetailSheet: ActiveRecipeDetailSheet?

    var body: some View {
        if let steps = recipe.steps, !steps.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("Method", systemImage: "checklist")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(steps.count) step\(steps.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.12))
                        .clipShape(.capsule)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            StepPreviewCard(step: step, index: index + 1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                .padding(.bottom, 10)

                Button {
                    activeRecipeDetailSheet = .steps(steps)
                } label: {
                    Label("View Steps", systemImage: "book.pages")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview {
    RecipeDetailsStepView(recipe: RecipeModel(name: "Carbonara"), activeRecipeDetailSheet: .constant(nil))
}
