//
//  EditStepRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/07/25.
//

import SwiftUI
import PhotosUI

struct EditStepRecipeView: View {
    @Binding var newStep: StepRecipe
    @Binding var stepImageItem: PhotosPickerItem?

    var body: some View {
        NewStepCard(newStep: $newStep, stepImageItem: $stepImageItem)
            .padding(.horizontal)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
    }
}

struct StepEditCard: View {
    var step: StepRecipe
    @Binding var steps: [StepRecipe]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageData = step.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 10))
            }

            Text(step.text.isEmpty ? "Step description" : step.text)
                .foregroundStyle(step.text.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        }
    }
}

private struct NewStepCard: View {
    @Binding var newStep: StepRecipe
    @Binding var stepImageItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageData = newStep.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(alignment: .topTrailing) {
                        Button(role: .destructive) {
                            withAnimation { newStep.image = nil; stepImageItem = nil }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .font(.title3)
                        }
                        .buttonStyle(.borderless)
                        .padding(8)
                    }
            } else {
                Menu {
                    PhotosPicker(selection: $stepImageItem, matching: .images, photoLibrary: .shared()) {
                        Label("Photo Library", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                } label: {
                    Label("Add photo", systemImage: "photo.badge.plus")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.borderless)
            }

            TextEditor(text: $newStep.text)
                .textEditorStyle(.plain)
                .autocorrectionDisabled()
                .frame(minHeight: 60)
                .overlay(alignment: .topLeading) {
                    if newStep.text.isEmpty {
                        Text("Describe this step")
                            .foregroundStyle(.tertiary)
                            .allowsHitTesting(false)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                }
        }
        .task(id: stepImageItem) {
            guard let item = stepImageItem,
                  let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let compressed = uiImage.resizedAndCompressed() else { return }
            withAnimation { newStep.image = compressed }
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker { data in
                withAnimation { newStep.image = data }
            }
        }
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.resizedAndCompressed() {
                parent.onCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    EditStepRecipeView(
        newStep: .constant(StepRecipe(text: "")),
        stepImageItem: .constant(nil)
    )
}
