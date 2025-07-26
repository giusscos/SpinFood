//
//  FoodListView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct FoodListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodModel.name) private var food: [FoodModel]
    
    @State private var searchText = ""
    @State private var showingLowStockOnly = false
    @State private var showingRefillConfirmation = false
    
    var filteredFood: [FoodModel] {
        var result = food
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if showingLowStockOnly {
            result = result.filter { $0.currentQuantity < $0.quantity * 0.2 }
        }
        
        return result
    }
    
    var foodToBeRefilled: [FoodModel] {
        food.filter { $0.currentQuantity < $0.quantity }
    }
    
    var body: some View {
        NavigationStack {
                List {
                    if !food.isEmpty {
                        Toggle("Low Stock", isOn: $showingLowStockOnly)
                    
                        if foodToBeRefilled.count > 0 {
                            Button {
                                showingRefillConfirmation = true
                            } label: {
                                Label("Refill food", systemImage: "cart.fill.badge.plus")
                            }
                        }
                    }
                    
                    if filteredFood.isEmpty {
                        Text("No food found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredFood) { item in
                            NavigationLink(destination: FoodDetailView(food: item)) {
                                FoodRowView(food: item)
                            }
                        }
                    }
                }
                .navigationTitle("Food")
                .searchable(text: $searchText, prompt: "Search food")
                .confirmationDialog(
                    "Refill All Food?",
                    isPresented: $showingRefillConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Refill") {
                        refillAllFood()
                    }
                    
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will refill all food items to their maximum quantity.")
                }
        }
    }
    
    private func refillAllFood() {
        let date = Date()
        
        for item in food where item.currentQuantity < item.quantity {
            let refill = FoodRefillModel(
                refilledAt: date,
                quantity: item.quantity - item.currentQuantity,
                unit: item.unit,
                food: item
            )
            
            modelContext.insert(refill)
            
            item.currentQuantity = item.quantity
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodModel.self, configurations: config)
    
    // Add sample food items
    let flour = FoodModel(name: "Flour", quantity: 1000, currentQuantity: 250, unit: .gram)
    let sugar = FoodModel(name: "Sugar", quantity: 500, currentQuantity: 50, unit: .gram)
    let milk = FoodModel(name: "Milk", quantity: 2, currentQuantity: 0.5, unit: .liter)
    
    container.mainContext.insert(flour)
    container.mainContext.insert(sugar)
    container.mainContext.insert(milk)
    
    return FoodListView()
        .modelContainer(container)
} 
