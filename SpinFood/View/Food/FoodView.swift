//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveSheet: Identifiable {
    case edit(FoodModal)
    case create
    
    var id: String {
        switch self {
        case .edit(let operation):
            return "editFood-\(operation.id)"
        case .create:
            return "createFood"
        }
    }
}


struct FoodView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModal]
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        List {
            if !foods.isEmpty {
                ForEach(foods) { food in
                    FoodRowView(food: food)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(food)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                activeSheet = .edit(food)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            } else {
                ContentUnavailableView("No food found", systemImage: "exclamationmark", description: Text("You can add your first food by clicking on the Add button"))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem (placement: .topBarLeading) {
                Button {
                    print("edit food")
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .labelStyle(.titleOnly)
                }
            }
            
            ToolbarItem (placement: .topBarTrailing) {
                Button {
                    activeSheet = .create
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit(let food):
                EditFoodView(food: food)
            case .create:
                CreateFoodView()
            }
        }
    }
}

#Preview {
    FoodView()
}
