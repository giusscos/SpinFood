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
                                
                                Text("\(item.currentQuantity) \(item.unit.abbreviation)")
                                    .font(.caption)
                                    .foregroundStyle(item.currentQuantity < item.quantity * 0.2 ? .red : .secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Food")
            .searchable(text: $searchText, prompt: "Search food")
        }
    }
}

#Preview {
    FoodListView()
        .modelContainer(for: [FoodModel.self], inMemory: true)
} 
