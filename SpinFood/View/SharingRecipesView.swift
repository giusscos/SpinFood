//
//  SharingRecipesView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI

struct ListFeature: Identifiable {
    var id: UUID = UUID()
    var image: String = ""
    var title: String = ""
    var body: String = ""
}

struct SharingRecipesView: View {
    var listFeatures: [ListFeature] = [
        ListFeature(image: "hand.raised", title: "Privacy first", body: "Your information are safe. You will only share your recipes with people you trust."),
        ListFeature(image: "bell.badge", title: "Get updates", body: "Data shared will appear in this section and you can also receive a notification if there's an update."),
        ListFeature(image: "switch.2", title: "You're in control", body: "You're in control of who can see your recipes. No one will see your private information without your permission.")
    ]

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    
                    VStack (spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.accent, .indigo)
                        
                        Text("Recipes sharing")
                            .font(.largeTitle)
                            .bold()
                    }
                    
                    Spacer()
                }
                
                VStack (alignment: .leading, spacing: 16) {
                    ForEach(listFeatures) { feature in
                        HStack (alignment: .top) {
                            Image(systemName: feature.image)
                                .font(.title3)
                                .imageScale(.large)
                                .foregroundStyle(.accent)
                            
                            VStack (alignment: .leading) {
                                Text(feature.title)
                                    .font(.headline)
                                
                                Text(feature.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                }
                
                VStack (spacing: 12) {
                    Button {
                        // Action to invite contact (future)
                    } label: {
                        Text("Share with someone")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.accentColor)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    
                    Button {
                        // Action to ask contact to share (future)
                    } label: {
                        Text("Ask to share")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(.indigo)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Sharing")
    }
}

#Preview {
    SharingRecipesView()
}
