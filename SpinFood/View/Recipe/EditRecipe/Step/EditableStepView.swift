//
//  EditableStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/09/25.
//

import SwiftUI
import PhotosUI

struct EditableStepView: View {
    var step: StepRecipe
    
    @Binding var steps: [StepRecipe]
    
    @Binding var imageToBeEdited: Data?
    
    @Binding var editingStepUUID: UUID?
    @Binding var textToBeEdited: String
    @Binding var editingImageItem: PhotosPickerItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let imageData = imageToBeEdited, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 400 : 220)
                    .clipShape(.rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .topTrailing) {
                        Button (role: .destructive) {
                            withAnimation {
                                editingImageItem = nil
                                imageToBeEdited = nil
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
            
            PhotosPicker(selection: $editingImageItem,
                         matching: .images,
                         photoLibrary: .shared()) {
                Text(editingImageItem != nil ? "Update step photo" : "Add step photo")
                    .font(.headline)
            }
                         .tint(.blue)
                         .buttonStyle(.borderedProminent)
                         .buttonBorderShape(.capsule)
            
            TextEditor(text: $textToBeEdited)
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
                    if textToBeEdited.isEmpty {
                        Text("Step to be edited")
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
                    .disabled(textToBeEdited.isEmpty)
                    .padding(4)
                }
                .submitLabel(.done)
                .onSubmit {
                    save()
                }
                .frame(minHeight: 48, maxHeight: 256)
        }
    }
    
    func save() {
        if textToBeEdited != "" {
            if let index = steps.firstIndex(where: { $0.id == step.id }) {
                steps[index].text = textToBeEdited
                steps[index].image = imageToBeEdited
            }
            
            textToBeEdited = ""
            imageToBeEdited = nil
            editingImageItem = nil
            
            editingStepUUID = nil
        }
    }
}

#Preview {
    EditableStepView(
        step: StepRecipe(text: ""),
        steps: .constant([]),
        imageToBeEdited: .constant(nil),
        editingStepUUID: .constant(nil),
        textToBeEdited: .constant(""),
        editingImageItem: .constant(nil)
    )
}
