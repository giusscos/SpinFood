//
//  RecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveRecipeSheet: Identifiable {
    case create
    case edit(RecipeModal)
    case view(RecipeModal)
    
    var id: String {
        switch self {
        case .create:
            return "createRecipe"
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
                    activeRecipeSheet = .create
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }
            }
        }
        .sheet(item: $activeRecipeSheet) { sheet in
            switch sheet {
            case .create:
                CreateRecipeView()
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
