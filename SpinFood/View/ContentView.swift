//
//  ContentView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Suggestions", systemImage: "sparkles.rectangle.stack.fill") {
                NavigationStack {
                    SuggestionsView()
                }
            }
            
            Tab("Recipes", systemImage: "fork.knife") {
                NavigationStack {
                    RecipeView()
                }
            }
            
            Tab("Foods", systemImage: "carrot.fill") {
                NavigationStack {
                    FoodView()
                }
            }
            
            Tab("Settings", systemImage: "gear") {
                NavigationStack {
                    SettingsView()
                }
            }
            
        }
    }

//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
}

#Preview {
    ContentView()
        .modelContainer(for: RecipeModal.self, inMemory: true)
}
