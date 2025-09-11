//
//  CreateStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI
import PhotosUI

struct CreateStepView: View {
    @Binding var steps: [StepRecipe]
    
    @Binding var newStep: StepRecipe
    @Binding var stepImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let imageData = newStep.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 400 : 220)
                    .clipShape(.rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .topTrailing) {
                        Button (role: .destructive) {
                            withAnimation {
                                stepImageItem = nil
                                newStep.image = nil
                            }
                        } label: {
                            Label("Delete image", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .padding()
                    }
            }
            
            PhotosPicker(selection: $stepImageItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                Text(stepImageItem != nil ? "Update step photo" : "Add step photo")
                    .font(.headline)
            }
                         .tint(.blue)
                         .buttonStyle(.borderedProminent)
                         .buttonBorderShape(.capsule)
            
            TextEditor(text: $newStep.text)
                .textEditorStyle(.plain)
                .autocorrectionDisabled()
                .padding(.leading, 8)
                .padding(.vertical, 6)
                .padding(.trailing, 26)
                .background(.thinMaterial)
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.secondary.opacity(0.5), lineWidth: 1)
                })
                .clipShape(.rect(cornerRadius: 20))
                .overlay(alignment: .topLeading, content: {
                    if newStep.text.isEmpty {
                        Text("New step")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                    }
                })
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .imageScale(.large)
                            .font(.title2)
                    }
                    .tint(.blue)
                    .buttonStyle(.borderless)
                    .disabled(newStep.text.isEmpty)
                    .padding(4)
                }
                .onSubmit {
                    save()
                }
                .frame(minHeight: 48, maxHeight: 256)
        }
        .padding()
    }
    
    func save() {
        if newStep.text != "" {
            steps.append(StepRecipe(text: newStep.text, image: newStep.image))
            
            newStep.text = ""
            newStep.image = nil
            stepImageItem = nil
        }
    }
}

#Preview {
    CreateStepView(
        steps: .constant([]),
        newStep: .constant(StepRecipe(text: "")),
        stepImageItem: .constant(nil)
    )
}
