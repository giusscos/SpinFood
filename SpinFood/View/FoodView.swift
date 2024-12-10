//
//  FoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct FoodView: View {
    @Query var foods: [FoodModal]
    
    var body: some View {
        List {
            if foods.isEmpty {
                ForEach(foods) { food in
                    Text("\(food.name)")
                }
            } else {
                ContentUnavailableView("No food found", systemImage: "exclamationmark")
            }
        }
        .listStyle(.plain)
        .navigationTitle("Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem (placement: .topBarLeading) {
                Button {
                    print("edit food")
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .labelStyle(.titleOnly)
                }
            }
            
            ToolbarItem (placement: .topBarTrailing) {
                Button {
                    print("add food")
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }
            }
        }
    }
}

#Preview {
    FoodView()
}
