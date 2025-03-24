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
    
    var id: String {
        switch self {
        case .create:
            return "createRecipe"
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        }
    }
}

struct RecipeView: View {
    @Environment(\.modelContext) var modelContext
    
    @Namespace var namespace
    
    @Query var recipes: [RecipeModal]
    
    @State private var activeRecipeSheet: ActiveRecipeSheet?
    
    var body: some View {
        ScrollView {
            if !recipes.isEmpty {
                ForEach(recipes) { value in
                    NavigationLink {
                        RecipeDetailsView(recipe: value)
                            .navigationTransition(.zoom(sourceID: value.id, in: namespace))
                    } label: {
                        RecipeRowView(recipe: value)
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
                    .matchedTransitionSource(id: value.id, in: namespace)
                }
            } else {
                ContentUnavailableView("No recipe found", systemImage: "exclamationmark", description: Text("You can add your first recipe by clicking on the 'Plus' button"))
                    .listRowSeparator(.hidden)
            }
        }
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
            }
        }
    }
}

#Preview {
    RecipeView()
}
