//
//  RecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeSheet: Identifiable {
    case edit(RecipeModal)
    case view(RecipeModal)
    
    var id: String {
        switch self {
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        case .view(let recipe):
            return "viewRecipe-\(recipe.id)"
        }
    }
}

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var recipes: [RecipeModal]
    
    @State private var activeRecipeSheet: ActiveRecipeSheet?
    
    @State var showCreateRecipe: Bool = false
    
    var body: some View {
        List {
            if !recipes.isEmpty {
                ForEach(recipes) { value in
                    RecipeRowView(recipe: value)
                        .onTapGesture {
                            activeRecipeSheet = .view(value)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(value)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                activeRecipeSheet = .edit(value)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            } else {
                ContentUnavailableView("No recipe found", systemImage: "exclamationmark", description: Text("You can add your first recipe by clicking on the 'Plus' button"))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle(Text("Recipes"))
        .toolbar {
            ToolbarItem (placement: .topBarTrailing) {
                Button {
                    showCreateRecipe.toggle()
                } label: {
                    Label("Add recipes", systemImage: "plus")
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateRecipe, content: {
            CreateRecipeView()
        })
        .sheet(item: $activeRecipeSheet) { sheet in
            switch sheet {
            case .edit(let value):
                EditRecipeView(recipe: value)
            case .view(let value):
                RecipeDetailsView(recipe: value)
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    RecipeView()
}
