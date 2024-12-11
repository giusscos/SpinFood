//
//  EditRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Bindable var recipe: RecipeModal
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                        
                } header: {
                    Text("Recipe details")
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem (placement: .topBarLeading, content: {
                    Button {
                        undoAndClose()
                    } label: {
                        Label("Undo", systemImage: "chevron.backward")
                            .labelStyle(.titleOnly)
                    }
                })
                
                ToolbarItem (placement: .topBarTrailing, content: {
                    Button {
                        saveFood()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .labelStyle(.titleOnly)
                    }
                })
            }
        }
        .onAppear() {
            
        }
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveFood() {
       
        dismiss()
    }
}

#Preview {
    EditRecipeView(recipe: RecipeModal(name: "Carbonara", duration: 13))
}
