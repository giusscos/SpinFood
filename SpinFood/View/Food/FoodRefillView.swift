//
//  FoodRefillView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 22/12/24.
//

import SwiftUI

struct FoodRefillView: View {
    @Environment(\.dismiss) var dismiss
    
    var food: [FoodModel]
    
    var body: some View {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text("Are you sure?")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("This are the food you will refill:")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                
                Section {
                    ForEach(food) { value in
                        HStack {
                            Text(value.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 6) {
                                HStack(spacing: 2) {
                                    Text("\(value.quantity - value.currentQuantity)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(value.unit.abbreviation)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Image(systemName: "arrow.right")
                                
                                HStack(spacing: 2) {
                                    Text("\(value.quantity)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text(value.unit.abbreviation)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Food")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        refillAllFood()
                    } label: {
                        Label("Confirm", systemImage: "checkmark")
                    }
                }
            }
        }
    
    func refillAllFood() {
        for value in food {
            value.currentQuantity = value.quantity
        }
        dismiss()
    }
}

#Preview {
    FoodRefillView(food: [])
}
