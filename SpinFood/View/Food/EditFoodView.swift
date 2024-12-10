//
//  EditFoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI

struct EditFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Bindable var food: FoodModal
    
    @State private var name: String = ""
    @State private var quantity: Decimal = 0.0
    @State private var currentQuantity: Decimal = 0.0
    @State private var unit: FoodUnit = .gram
    //    @State private var image: Data? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    DecimalField(title: "Quantity", value: $quantity)
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(FoodUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                } header: {
                    Text("Food details")
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem (placement: .topBarLeading, content: {
                    Button {
                        undoAndClose()
                    } label: {
                        Label("Undo", systemImage: "chevron.backward")
                            .labelStyle(.titleOnly)
                    }
                })
                
                ToolbarItem (placement: .topBarTrailing, content: {
                    Button {
                        saveFood()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                            .labelStyle(.titleOnly)
                    }
                })
            }
        }
        .onAppear() {
            name = food.name
            quantity = food.quantity
            currentQuantity = food.currentQuantity
            unit = food.unit
        }
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveFood() {
        food.name = name
        food.quantity = quantity
        food.currentQuantity = quantity
        food.unit = unit
        
        dismiss()
    }
}

#Preview {
    EditFoodView(food: FoodModal(name: "Carrot"))
}
