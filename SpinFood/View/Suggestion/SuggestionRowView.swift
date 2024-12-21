//
//  SuggestionRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 21/12/24.
//

import SwiftUI

struct SuggestionRowView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .foregroundStyle(Color.red)
            .frame(minHeight: 75)
            .aspectRatio(4/3, contentMode: .fit)
            .overlay(alignment: .bottom, content: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbonara")
                        .font(.title)
                        .fontWeight(.semibold)
                        .shadow(radius: 10, x: 0, y: 4)
                    
                    ScrollView (.horizontal) {
                        HStack {
                            ForEach(0..<10) { index in
                                Text("Ingredient \(index)")
                                    .padding(8)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 6, x: 0, y: 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(8)
            })
            
    }
}

#Preview {
    SuggestionRowView()
}
