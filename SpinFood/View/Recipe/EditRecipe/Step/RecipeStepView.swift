//
//  RecipeStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI

struct RecipeStepView: View {
    var step: StepRecipe
    
    @Binding var steps: [StepRecipe]
    
    @Binding var editingStepUUID: UUID?
    @Binding var textToBeEdited: String
    @Binding var imageToBeEdited: Data?
    
    var body: some View {
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
                .padding(.vertical, 4)
        }
        .onTapGesture {
            editingStepUUID = step.id
            
            textToBeEdited = step.text
            imageToBeEdited = step.image
        }
        .swipeActions {
            Button(role: .destructive) {
                steps.removeAll(where: { $0.id == step.id })
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                editingStepUUID = step.id
                
                textToBeEdited = step.text
                imageToBeEdited = step.image
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

#Preview {
    RecipeStepView(
        step: StepRecipe(text: ""),
        steps: .constant([]),
        editingStepUUID: .constant(nil),
        textToBeEdited: .constant(""),
        imageToBeEdited: .constant(nil)
    )
}
