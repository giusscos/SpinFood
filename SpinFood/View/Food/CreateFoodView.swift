//
//  CreateFoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct CreateFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name: String = ""
    @State private var quantity: Decimal = 0.0
    @State private var currentQuantity: Decimal = 0.0
    @State private var unit: FoodUnit = .gram
    
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
            .navigationTitle("Create Food")
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
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveFood() {
        let newFood = FoodModal(
            name: name,
            quantity: quantity,
            currentQuantity: quantity,
            unit: unit,
//            image: image,
            createdAt: .now
        )
        
        newFood.rating = 0
        
        modelContext.insert(newFood)
        
        dismiss()
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    CreateFoodView()
}
