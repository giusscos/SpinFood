//
//  EditStepRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/07/25.
//

import SwiftUI
import PhotosUI

struct EditStepRecipeView: View {
    @Binding var steps: [StepRecipe]
    
    @Binding var newStep: StepRecipe
    @Binding var stepImageItem: PhotosPickerItem?
    
    @State var imageToBeEdited: Data?
    
    @State var editingStepUUID: UUID?
    @State var textToBeEdited: String = ""
    @State var editingImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            if !steps.isEmpty {
                HStack {
                    Text("Steps")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                ForEach(steps) { step in
                    if let editingStepUUID = editingStepUUID, editingStepUUID == step.id {
                        EditableStepView(step: step, steps: $steps, imageToBeEdited: $imageToBeEdited, editingStepUUID: $editingStepUUID, textToBeEdited: $textToBeEdited, editingImageItem: $editingImageItem)
                    } else {
                        RecipeStepView(step: step, steps: $steps, editingStepUUID: $editingStepUUID, textToBeEdited: $textToBeEdited, imageToBeEdited: $imageToBeEdited)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            CreateStepView(steps: $steps, newStep: $newStep, stepImageItem: $stepImageItem)
        }
    }
}

#Preview {
    EditStepRecipeView(
        steps: .constant([]),
        newStep: .constant(StepRecipe(text: "")),
        stepImageItem: .constant(nil)
    )
}
