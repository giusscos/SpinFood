//
//  RecipeDetailsStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

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
