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
    
    var size: CGSize
    
    var body: some View {
        Section {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: size.height * 0.5)
                    .mask(
                        LinearGradient(colors: [.black, .black, .black, .black, .clear, .clear], startPoint: .top, endPoint: .bottom)
                            .blur(radius: 16)
                    )
                    .overlay (alignment: .bottom, content: {
                        Menu {
                            Button {
                                withAnimation {
                                    self.imageData = nil
                                    imageItem = nil
                                }
                            } label: {
                                Label("Remove Photo", systemImage: "xmark")
                            }
                            
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Update Photo", systemImage: "photo")
                            }
                        } label: {
                            Text("Edit Photo")
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .foregroundColor(.primary)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                        .padding(.vertical)
                    })
            } else {
                Button {
                    showPhotoPicker = true
                } label: {
                    VStack (spacing: 16) {
                        Image(systemName: "photo")
                            .font(.title)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(.circle)
                        
                        Text("Add Photo")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(.ultraThinMaterial)
                            .clipShape(.capsule)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(minHeight: size.height * 0.5)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

#Preview {
    EditRecipePhotoView(imageItem: .constant(nil), imageData: .constant(nil), showPhotoPicker: .constant(false), size: CGSize(width: 300, height: 200))
}
