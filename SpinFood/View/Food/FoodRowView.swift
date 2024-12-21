//
//  FoodRowView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI

struct FoodRowView: View {
    var food: FoodModal
    
    var body: some View {
        HStack {
            Text(food.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack (alignment: .lastTextBaseline, spacing: 2) {
                VStack {
                    if food.quantity != food.currentQuantity {
                        Text("\(food.quantity)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)
                        
                        Text("\(food.currentQuantity)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    } else {
                        Text("\(food.quantity)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                Text(food.unit.abbreviation)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }.padding(8)
    }
}

#Preview {
    FoodRowView(food: FoodModal(name: "Carrot", quantity: 10))
}
