//
//  FoodRowView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 26/07/25.
//

import SwiftUI

struct FoodRowView: View {
    var food: FoodModel
    
    var body: some View {
        HStack {
            Text(food.name)
                .font(.headline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack (alignment: .trailing) {
                if food.quantity != food.currentQuantity {
                    Group {
                        Text("\(food.quantity)")
                        +
                        Text(food.unit.abbreviation)
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                }
                
                HStack (alignment: .lastTextBaseline, spacing: 2) {
                    if food.quantity != food.currentQuantity {
                        Text("\(food.currentQuantity)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    } else {
                        Text("\(food.quantity)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(food.unit.abbreviation)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    FoodRowView(food: FoodModel(name: "Apple"))
}
