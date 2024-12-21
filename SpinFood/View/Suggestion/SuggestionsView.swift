//
//  SuggestionsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI

struct SuggestionsView: View {
    var body: some View {
        List {
            ForEach(0..<10) { _ in
                SuggestionRowView()
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Suggestions for you")
    }
}

#Preview {
    SuggestionsView()
}
