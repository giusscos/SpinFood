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
    
    @State var toggleFoodSheet: Bool = false
    
    var body: some View {
        List {
            if !foods.isEmpty {
                ForEach(foods) { food in
                    Text("\(food.name)")
                }
            } else {
                ContentUnavailableView("No food found", systemImage: "exclamationmark", description: Text("You can add your first food by clicking on the Add button"))
                    .listRowSeparator(.hidden)
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
                    toggleFoodSheet.toggle()
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleOnly)
                }
            }
        }
        .sheet(isPresented: $toggleFoodSheet) {
            CreateFoodView()
        }
    }
}

#Preview {
    FoodView()
}
