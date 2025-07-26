//
//  FoodDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct FoodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var food: FoodModel
    
    @State private var showingRefillDialog = false
        
    var body: some View {
        List {
            VStack {
                if food.quantity != food.currentQuantity {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Current")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(food.currentQuantity)")
                                .font(.headline)
                                .foregroundStyle(food.currentQuantity < food.quantity * 0.2 ? .red : .primary)
                            +
                            Text("\(food.unit.abbreviation)")
                                .font(.subheadline)
                                .foregroundStyle(food.currentQuantity < food.quantity * 0.2 ? .red : .secondary)
                            
                        }
                        
                        Image(systemName: "arrow.right")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("Initial")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\(food.quantity)")
                                .font(.headline)
                            +
                            Text("\(food.unit.abbreviation)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        showingRefillDialog = true
                    } label: {
                        Text("Refill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(food.quantity == food.currentQuantity)
                    .padding(.vertical)
                } else {
                    Text("\(food.quantity)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    +
                    Text("\(food.unit.abbreviation)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let refills = food.refills, !refills.isEmpty {
                Section {
                    // Simplify the complex expression
                    let sortedRefills = refills.sorted(by: { $0.refilledAt > $1.refilledAt })
                    let recentRefills = sortedRefills.prefix(3)
                    
                    ForEach(Array(recentRefills)) { refill in
                        VStack(alignment: .leading) {
                            Text("\(refill.quantity)")
                                .font(.headline)
                            +
                            Text("\(refill.unit.abbreviation)")
                                .font(.subheadline)
                            
                            Text(refill.refilledAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Recent Refills")
                }
            }
        }
        .navigationTitle(food.name)
        .confirmationDialog(
            "Refill \(food.name)?",
            isPresented: $showingRefillDialog,
            titleVisibility: .visible
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Refill") {
                refill()
            }
        } message: {
            Text("This will refill \(food.name) to his maximum quantity.")
        }
    }
    
    private func refill() {
        let foodRefill = FoodRefillModel(
            refilledAt: Date(),
            quantity: food.quantity - food.currentQuantity,
            unit: food.unit,
            food: food
        )
        
        modelContext.insert(foodRefill)
        
        food.currentQuantity = food.quantity
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FoodModel.self, configurations: config)
    
    let sampleFood = FoodModel(name: "Flour", quantity: 1000, currentQuantity: 400, unit: .gram)
    container.mainContext.insert(sampleFood)
    
    return FoodDetailView(food: sampleFood)
        .modelContainer(container)
} 
