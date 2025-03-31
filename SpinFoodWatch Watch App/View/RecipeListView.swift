//
//  RecipeListView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecipeModel.name) private var recipes: [RecipeModel]
    
    @State private var searchText = ""
    
    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredRecipes.isEmpty {
                    Text("No recipes found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                if let imageData = recipe.image,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .overlay (alignment: .bottom) {
                                            Color.clear
                                                .background(.ultraThinMaterial)
                                                .frame(maxWidth: .infinity)
                                                .mask(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.black, .black, .clear, .clear, .clear]),
                                                        startPoint: .bottom,
                                                        endPoint: .top
                                                    )
                                                )
                                                .overlay(alignment: .bottom) {
                                                    VStack (alignment: .leading) {
                                                        Text("\(recipe.duration.formatted)")
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                        
                                                        Text(recipe.name)
                                                            .font(.headline)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .tint(.primary)
                                                    .multilineTextAlignment(.leading)
                                                    .padding(8)
                                                }
                                        }
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    // Add sample recipe with image
    let sampleRecipe = RecipeModel(name: "Pasta Carbonara")
    if let imageData = UIImage(systemName: "fork.knife")?.pngData() {
        sampleRecipe.image = imageData
    }
    container.mainContext.insert(sampleRecipe)
    
    return RecipeListView()
        .modelContainer(container)
} 
