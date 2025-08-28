//
//  FoodRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI

struct FoodRowView: View {
    var food: FoodModel
    
    var body: some View {
        HStack {
            Text(food.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack (alignment: .trailing) {
                if food.quantity != food.currentQuantity {
                    HStack (spacing: 2) {
                        Text("Initial: ")
                        
                        Text(food.quantity, format: .number)
                        +
                        Text(food.unit.abbreviation)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                }
                
                HStack (alignment: .lastTextBaseline, spacing: 2) {
                    if food.quantity != food.currentQuantity {
                        Text(food.currentQuantity, format: .number)
                            .font(.headline)
                            .fontWeight(.semibold)
                    } else {
                        Text(food.quantity, format: .number)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(food.unit.abbreviation)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    FoodRowView(food: FoodModel(name: "Carrot", quantity: 10))
}
