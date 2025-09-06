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
    @Binding var showAdjustPhoto: Bool
    
    var safeArea: EdgeInsets
    var size: CGSize
    
    var body: some View {
        let height = size.height * 0.45
        
        GeometryReader { geometry in
            let size = geometry.size
            let minY = geometry.frame(in: .named("Scroll")).minY
            let progress = (minY > 0 ? minY : 0) / (height * 0.8)
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                    .clipped()
                    .mask(
                        ZStack (alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    .linearGradient(colors: [
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(1),
                                        .black.opacity(0.75 - progress),
                                        .black.opacity(0.50 - progress),
                                        .black.opacity(0.25 - progress),
                                        .black.opacity(0 - progress),
                                    ], startPoint: .top, endPoint: .bottom)
                                )
                        }
                    )
                    .overlay (alignment: .bottom, content: {
                        Menu {
                            Button {
                                withAnimation {
                                    self.imageData = nil
                                    imageItem = nil
                                }
                            } label: {
                                Label("Remove", systemImage: "xmark")
                            }
                            
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Update", systemImage: "photo")
                            }
                            
//                            Button {
//                                withAnimation {
//                                    showAdjustPhoto = true
//                                }
//                            } label: {
//                                Label("Adjust", systemImage: "crop")
//                            }
                        } label: {
                            Text("Edit background".capitalized)
                                .font(.headline)
                        }
                        .foregroundStyle(.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .clipShape(.capsule)
                    })
                    .offset(y: (minY > 0 ? -minY : 0))
            } else {
                HStack {
                    Spacer()
                    
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
                                .foregroundStyle(.primary)
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                                .background(.ultraThinMaterial)
                                .clipShape(.capsule)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .frame(height: size.height, alignment: .center)
            }
        }
        .frame(height: height + safeArea.top)
    }
}

#Preview {
    EditRecipePhotoView(
        imageItem: .constant(nil),
        imageData: .constant(nil),
        showPhotoPicker: .constant(false),
        showAdjustPhoto: .constant(false),
        safeArea: EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)),
        size: CGSize(width: 300, height: 200)
    )
}

