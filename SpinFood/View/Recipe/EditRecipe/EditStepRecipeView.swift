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
        Section {
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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .task(id: stepImageItem) {
            if let data = try? await stepImageItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let compressedData = uiImage.resizedAndCompressed() {
                withAnimation {
                    newStep.image = compressedData
                }
            }
        }
        .task(id: editingImageItem) {
            if let data = try? await editingImageItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let compressedData = uiImage.resizedAndCompressed() {
                withAnimation(.smooth) {
                    imageToBeEdited = compressedData
                }
            }
        }
    }
}

#Preview {
    EditStepRecipeView(steps: .constant([]), newStep: .constant(StepRecipe(text: "")), stepImageItem: .constant(nil))
}

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
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: UIDevice.current.userInterfaceIdiom == .pad ? 400 : 220)
                    .clipShape(.rect(cornerRadius: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .swipeActions(edge: .trailing) {
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
