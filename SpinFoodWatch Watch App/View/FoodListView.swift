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
    @State private var showingAutoRefillConfirmation = false
    
    // Add formatter for decimal values
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // Helper method to format decimal values
    private func formatDecimal(_ value: Decimal) -> String {
        return decimalFormatter.string(from: value as NSNumber) ?? "0.0"
    }
    
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
    
    var body: some View {
        NavigationStack {
                List {
                    Toggle("Low Stock Only", isOn: $showingLowStockOnly)
                    
                    if !food.isEmpty {
                        Button {
                            showingAutoRefillConfirmation = true
                        } label: {
                            Label("Refill All", systemImage: "cart.fill.badge.plus")
                        }
                    }
                    
                    if filteredFood.isEmpty {
                        Text("No food items found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredFood) { item in
                            NavigationLink(destination: FoodDetailView(food: item)) {
                                HStack {
                                    Text(item.name)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text("\(formatDecimal(item.currentQuantity)) \(item.unit.abbreviation)")
                                        .font(.caption)
                                        .foregroundStyle(item.currentQuantity < item.quantity * 0.2 ? .red : .secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Food")
                .searchable(text: $searchText, prompt: "Search food")
                .confirmationDialog(
                    "Auto Refill All Food?",
                    isPresented: $showingAutoRefillConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Refill All") {
                        autoRefillAllFood()
                    }
                    
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will refill all food items to their maximum quantity.")
                }
        }
    }
    
    // Function to auto-refill all food items
    private func autoRefillAllFood() {
        let date = Date()
        
        for item in food where item.currentQuantity < item.quantity {
            let refillAmount = item.quantity - item.currentQuantity
            
            // Create a refill record
            let refill = FoodRefillModel(
                food: item,
                quantity: refillAmount,
                unit: item.unit,
                date: date
            )
            
            // Add refill to the model context
            modelContext.insert(refill)
            
            // Update the food quantity to maximum
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
