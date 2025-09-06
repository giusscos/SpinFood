//
//  EditCropImageView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 02/09/25.
//

import SwiftUI

struct EditCropImageView: View {
    @Binding var imageData: Data?
    
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    
    @Binding var imageFrameSize: CGSize
    
    var safeArea: EdgeInsets
    var size: CGSize
    
    // Minimum and maximum scale for pinch gesture
    private let minimumScale: CGFloat = 1.0
    private let maximumScale: CGFloat = 5.0
    
    var body: some View {
        let height = size.height * 0.45
        
        GeometryReader { geometry in
            let frameSize = geometry.size
            
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: frameSize.width * scale,
                        height: frameSize.height * scale
                    )
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    let newScale = max(minimumScale, min(lastScale * value.magnification, maximumScale))
                                    scale = newScale
                                    
                                    // Adjust offset to keep image within bounds
                                    adjustOffsetForBounds(frameSize: frameSize)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    // Update offset based on drag
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    
                                    // Adjust offset to keep image within bounds
                                    adjustOffsetForBounds(frameSize: frameSize)
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .frame(width: frameSize.width, height: frameSize.height)
                    .clipped()
                    .onAppear() {
                        imageFrameSize = frameSize
                    }
            }
        }
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
                            .black.opacity(0.75),
                            .black.opacity(0.50),
                            .black.opacity(0.25),
                            .black.opacity(0),
                        ], startPoint: .top, endPoint: .bottom)
                    )
            }
        )
        .overlay(alignment: .bottom) {
            Text("Pinch to Crop".capitalized)
                .font(.headline)
                .padding(.vertical, 6)
                .padding(.horizontal)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
        }
        .frame(height: height + safeArea.top)
    }
    
    // Adjust offset to ensure image stays within frame boundaries
    private func adjustOffsetForBounds(frameSize: CGSize) {
        let scaledWidth = frameSize.width * scale
        let scaledHeight = frameSize.height * scale
        
        // Calculate bounds for offset
        let maxOffsetX = (scaledWidth - frameSize.width) / 2
        let maxOffsetY = (scaledHeight - frameSize.height) / 2
        
        // Ensure horizontal borders (left and right) stay within frame
        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        
        // Ensure top border stays within frame (prevent moving too far down)
        offset.height = max(min(offset.height, maxOffsetY), -maxOffsetY)
        
        // If zoomed, ensure the top edge doesn't go below the frame's top
        if scale > 1.0 {
            let topBound = (scaledHeight - frameSize.height) / 2
            offset.height = min(offset.height, topBound)
        }
    }
}

#Preview {
    EditCropImageView(
        imageData: .constant(nil),
        offset: .constant(CGSize(width: 300, height: 400)),
        lastOffset: .constant(CGSize(width: 300, height: 400)),
        scale: .constant(1.0),
        lastScale: .constant(1.0),
        imageFrameSize: .constant(CGSize(width: 300, height: 400)),
        safeArea: EdgeInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0)),
        size: CGSize(width: 300, height: 200)
    )
}
