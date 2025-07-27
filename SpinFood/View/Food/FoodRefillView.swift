//
//  FoodRefillView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import SwiftUI

struct FoodRefillView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var food: [FoodModel]
    
    var body: some View {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Group {
                            Text(food.count == 1 ? "This is" : "These are")
                            +
                            Text(" the food you will refill:")
                        }
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    }
                }
                .listRowInsets(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                Section {
                    ForEach(food) { value in
                        HStack {
                            Text(value.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 6) {
                                VStack (alignment: .trailing) {
                                    HStack (alignment: .lastTextBaseline, spacing: 0) {
                                        Text("Needed")
                                
                                        Image(systemName: "arrow.down")
                                            .imageScale(.small)
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    
                                    HStack (alignment: .lastTextBaseline, spacing: 2) {
                                        Text("\(value.quantity - value.currentQuantity)")
                                        
                                        Text(value.unit.abbreviation)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                    
                                Image(systemName: "arrow.right")
                                
                                VStack (alignment: .trailing) {
                                    HStack (alignment: .lastTextBaseline, spacing: 0) {
                                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                                            Text("Goal")
                                            
                                            Image(systemName: "arrow.down")
                                                .imageScale(.small)
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        
                                    }
                                    HStack (alignment: .lastTextBaseline, spacing: 2) {
                                        Text("\(value.quantity)")
                                                                                    
                                        Text(value.unit.abbreviation)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Ready to refill?")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refillAllFood()
                    } label: {
                        Text("Confirm")
                    }
                }
            }
        }
    
    func refillAllFood() {
        for value in food {
            if value.currentQuantity < value.quantity {
                let refillAmount = value.quantity - value.currentQuantity
                
                // Create a new refill record
                let refill = FoodRefillModel(
                    refilledAt: Date.now,
                    quantity: refillAmount,
                    unit: value.unit,
                    food: value
                )
                
                modelContext.insert(refill)
                
                // Update the current quantity
                value.currentQuantity = value.quantity
            }
        }
        dismiss()
    }
}

#Preview {
    FoodRefillView(food: [])
}
