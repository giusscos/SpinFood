//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

enum ActiveFoodSheet: Identifiable {
    case edit(FoodModal)
    case create
    
    var id: String {
        switch self {
        case .edit(let food):
            return "editFood-\(food.id)"
        case .create:
            return "createFood"
        }
    }
}

struct FoodView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var food: [FoodModal]
    
    @State private var activeSheet: ActiveFoodSheet?
    
    var body: some View {
        List {
            if !food.isEmpty {
                ForEach(food) { food in
                    FoodRowView(food: food)
                        .onTapGesture {
                            activeSheet = .edit(food)
                        }
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
                Menu {
                    Button {
                        refillAllFood()
                    } label: {
                        Label("Refill food", systemImage: "bag.fill.badge.plus")
                            .labelStyle(.titleOnly)
                    }
                    
                    Button {
                        activeSheet = .create
                    } label: {
                        Label("Add", systemImage: "plus")
                            .labelStyle(.titleOnly)
                    }
                } label: {
                    Label("Menu", systemImage: "ellipsis.circle")
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
    
    func refillAllFood() {
        for value in food {
            value.currentQuantity = value.quantity
        }
    }
}

#Preview {
    FoodView()
}
