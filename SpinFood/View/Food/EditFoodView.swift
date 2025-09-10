//
//  EditFoodView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var food: FoodModel?
    
    @State private var name: String = ""
    @State private var quantity: Decimal?
    @State private var currentQuantity: Decimal?
    @State private var unit: FoodUnit = .gram
    
    enum Field: Hashable {
        case name
        case quantity
        case currentQuantity
    }
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .quantity
                        }

                    HStack {
                        Text("Quantity")
                        
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .submitLabel(food != nil ? .next : .done)
                            .onSubmit {
                                focusedField = food != nil ? .currentQuantity : nil
                            }
                    }
                    
                    if food != nil {
                        HStack {
                            Text("Current quantity")
                            
                            TextField("Current quantity", value: $currentQuantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                        }
                    }
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(FoodUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.capitalized).tag(unit)
                        }
                    }
                } header: {
                    Text("Food details")
                }
            }
            .navigationTitle(food != nil ? "Edit food" : "Create food")
            .toolbar {
                ToolbarItem (placement: .topBarTrailing, content: {
                    Button {
                        saveFood()
                    } label: {
                        Text("Save")
                    }
                    .disabled(name.isEmpty)
                })
            }
            .onAppear() {
                focusedField = .name
                
                if let food = food {
                    name = food.name
                    quantity = food.quantity
                    currentQuantity = food.currentQuantity
                    unit = food.unit
                }
            }
        }
    }
    
    func saveFood() {        
        if let food = food {
            food.name = name
            if let currentQuantity = currentQuantity {
                food.currentQuantity = currentQuantity
            }
            
            quantity = currentQuantity
            
            if let quantity = quantity {
                food.quantity = quantity
            }
            food.unit = unit
        } else {
            let newFood = FoodModel(
                name: name,
                quantity: quantity ?? 0,
                currentQuantity: quantity ?? 0,
                unit: unit,
                createdAt: .now
            )
            
            modelContext.insert(newFood)
        }
        
        dismiss()
    }
}

#Preview {
    EditFoodView(food: FoodModel(name: "Carrots"))
}
