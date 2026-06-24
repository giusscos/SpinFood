//
//  EditRecipePhotoView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/07/25.
//

import SwiftUI
import PhotosUI

struct EditRecipePhotoView: View {
    @Binding var imageItem: PhotosPickerItem?
    @Binding var imageData: Data?
    @Binding var showPhotoPicker: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Photo or placeholder
            Group {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 260, height: 220)
                        .clipped()
                } else {
                    ZStack {
                        Color(UIColor.secondarySystemFill)

                        Image(systemName: "camera")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 260, height: 220)
                }
            }
            .padding(12)
            .padding(.bottom, 52)
            .background(.white)
            .clipShape(.rect(cornerRadius: 2))
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)

            if imageData != nil {
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Update", systemImage: "photo")
                    }

                    Button(role: .destructive) {
                        withAnimation {
                            imageData = nil
                            imageItem = nil
                        }
                    } label: {
                        Label("Remove", systemImage: "xmark")
                    }
                } label: {
                    Label("Edit photo", systemImage: "pencil")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.accent, in: .capsule)
                }
            } else {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Choose photo", systemImage: "camera.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.accent, in: .capsule)
                }
            }
        }
    }
}

#Preview {
    EditRecipePhotoView(
        imageItem: .constant(nil),
        imageData: .constant(nil),
        showPhotoPicker: .constant(false)
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
