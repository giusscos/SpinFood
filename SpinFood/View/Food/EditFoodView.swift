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
    @State private var category: FoodCategory = .other
    @State private var hasExpiryDate: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    enum Field: Hashable {
        case name, quantity, currentQuantity
    }

    @FocusState private var focusedField: Field?

    var isEditing: Bool { food != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food details") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .quantity }

                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    Picker("Unit", selection: $unit) {
                        ForEach(FoodUnit.allCases, id: \.self) { u in
                            Text(u.rawValue).tag(u)
                        }
                    }
                }

                Section("Quantity") {
                    HStack {
                        Text("Stock quantity")
                        Spacer()
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .quantity)
                            .submitLabel(isEditing ? .next : .done)
                            .onSubmit { focusedField = isEditing ? .currentQuantity : nil }
                        Text(unit.abbreviation)
                            .foregroundStyle(.secondary)
                    }

                    if isEditing {
                        HStack {
                            Text("Current quantity")
                            Spacer()
                            TextField("0", value: $currentQuantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .currentQuantity)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                            Text(unit.abbreviation)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Expiry date") {
                    Toggle("Track expiry date", isOn: $hasExpiryDate)

                    if hasExpiryDate {
                        DatePicker(
                            "Expires on",
                            selection: $expiryDate,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Food" : "Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFood() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                focusedField = .name
                if let food {
                    name = food.name
                    quantity = food.quantity
                    currentQuantity = food.currentQuantity
                    unit = food.unit
                    category = food.category
                    if let expiry = food.expiryDate {
                        hasExpiryDate = true
                        expiryDate = expiry
                    }
                }
            }
        }
    }

    private func saveFood() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let food {
            food.name = trimmedName
            food.category = category
            food.unit = unit
            food.expiryDate = hasExpiryDate ? expiryDate : nil
            if let q = quantity { food.quantity = q }
            if let cq = currentQuantity { food.currentQuantity = cq }
        } else {
            let newFood = FoodModel(
                name: trimmedName,
                quantity: quantity ?? 0,
                currentQuantity: quantity ?? 0,
                unit: unit,
                category: category,
                expiryDate: hasExpiryDate ? expiryDate : nil
            )
            modelContext.insert(newFood)
        }

        dismiss()
    }
}

#Preview {
    EditFoodView()
}
