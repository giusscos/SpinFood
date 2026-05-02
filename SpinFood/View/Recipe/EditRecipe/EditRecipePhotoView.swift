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
        ZStack(alignment: .bottom) {
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
                        Color.secondary.opacity(0.10)

                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)

                            Text("Add Photo")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 260, height: 220)
                }
            }
            .padding(12)
            .padding(.bottom, 52)
            .background(.white)
            .clipShape(.rect(cornerRadius: 2))
            .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
            .rotationEffect(.degrees(-1.5))

            // Edit button sits inside the white bottom strip
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
                    Text("Edit photo")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.06), in: .capsule)
                }
                .padding(.bottom, 14)
            } else {
                Button {
                    showPhotoPicker = true
                } label: {
                    Text("Choose photo")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.06), in: .capsule)
                }
                .padding(.bottom, 14)
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
