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
                        Text("Are you sure?")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Group {
                            Text(food.count == 1 ? "This is" : "These are")
                            +
                            Text("the food you will refill:")
                        }
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                    }
                }
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
                                    
                                    Text("\(value.quantity - value.currentQuantity)")
                                }
                                    
                                Image(systemName: "arrow.right")
                                
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    VStack (alignment: .trailing) {
                                        HStack (alignment: .lastTextBaseline, spacing: 0) {
                                            Text("Goal")
                                            
                                            Image(systemName: "arrow.down")
                                                .imageScale(.small)
                                        }
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        
                                        Text("\(value.quantity)")
                                            .fontWeight(.semibold)
                                    }
   
                                    Text(value.unit.abbreviation)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.headline)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        refillAllFood()
                    } label: {
                        Text("Confirm")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
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
