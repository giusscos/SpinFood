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
    
    @State private var showingRefillSheet = false
    @State private var refillQuantity: Double = 0
    @State private var selectedUnit: FoodUnit = .gram
    
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Food quantity status
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current quantity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(formatDecimal(food.currentQuantity)) \(food.unit.abbreviation)")
                            .font(.title3)
                            .foregroundStyle(food.currentQuantity < food.quantity * 0.2 ? .red : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .trailing) {
                        Text("Total quantity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(formatDecimal(food.quantity)) \(food.unit.abbreviation)")
                            .font(.title3)
                    }
                }
                
                Divider()
                
                // Refill button
                Button {
                    // Initialize sheet with current values
                    refillQuantity = 0
                    selectedUnit = food.unit
                    showingRefillSheet = true
                } label: {
                    Label("Refill", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                
                // Recent refill history
                if let refills = food.refills, !refills.isEmpty {
                    Section {
                        // Simplify the complex expression
                        let sortedRefills = refills.sorted(by: { $0.date > $1.date })
                        let recentRefills = sortedRefills.prefix(3)
                        
                        ForEach(Array(recentRefills)) { refill in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(formatDecimal(refill.quantity)) \(refill.unit.abbreviation)")
                                        .font(.callout)
                                    
                                    Text(refill.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("Recent Refills")
                            .font(.headline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(food.name)
        .sheet(isPresented: $showingRefillSheet) {
            // Refill sheet
            NavigationStack {
                Form {
                    Section {
                        TextField("Quantity", value: $refillQuantity, format: .number)
                        
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(FoodUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                    }
                    
                    Section {
                        Button("Add Refill") {
                            addRefill()
                            showingRefillSheet = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Refill \(food.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingRefillSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.4)])
        }
    }
    
    private func addRefill() {
        guard refillQuantity > 0 else { return }
        
        let decimal = Decimal(refillQuantity)
        
        // Create a refill record
        let refill = FoodRefillModel(
            food: food,
            quantity: decimal,
            unit: selectedUnit,
            date: Date()
        )
        
        // Add refill to the model context
        modelContext.insert(refill)
        
        // Update the food quantity
        // Convert quantity if units don't match
        if selectedUnit == food.unit {
            // Same units, direct addition
            food.currentQuantity += decimal
        } else {
            // Different units, conversion needed
            // First, convert input to grams
            let inputInGrams = selectedUnit.convertToGrams(decimal)
            
            // Then, calculate equivalent in food's unit
            let foodUnitBase = food.unit.convertToGrams(Decimal(1))
            let convertedQuantity = inputInGrams / foodUnitBase
            
            // Update food quantity
            food.currentQuantity += convertedQuantity
        }
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
