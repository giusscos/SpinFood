import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: FoodModel?

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var quantity: Decimal?
    @State private var currentQuantity: Decimal?
    @State private var unit: FoodUnit = .gram
    @State private var category: FoodCategory = .other
    @State private var hasExpiryDate: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var showEmojiPicker: Bool = false

    enum Field: Hashable {
        case name, quantity, currentQuantity
    }

    @FocusState private var focusedField: Field?

    var isEditing: Bool { food != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Emoji") {
                    Button {
                        focusedField = nil
                        showEmojiPicker = true
                    } label: {
                        HStack {
                            Text("Food emoji")
                                .foregroundStyle(.primary)
                            Spacer()
                            if emoji.isEmpty {
                                Text("None selected")
                                    .foregroundStyle(.secondary)
                                    .font(.system(.subheadline, design: .rounded))
                            } else {
                                Text(emoji)
                                    .font(.system(size: 30))
                            }
                        }
                    }
                }

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
                    emoji = food.emoji
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
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selectedEmoji: $emoji)
            }
        }
    }

    private func saveFood() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let food {
            food.name = trimmedName
            food.emoji = emoji
            food.category = category
            food.unit = unit
            food.expiryDate = hasExpiryDate ? expiryDate : nil
            if let q = quantity { food.quantity = q }
            if let cq = currentQuantity { food.currentQuantity = cq }
        } else {
            let newFood = FoodModel(
                name: trimmedName,
                emoji: emoji,
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

// MARK: - Emoji Picker Sheet

struct EmojiPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedEmoji: String
    @State private var customInput: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    private let emojiGroups: [(String, [String])] = [
        ("Fruits", ["🍎", "🍊", "🍋", "🍇", "🍓", "🍌", "🍉", "🫐", "🍑", "🥭", "🍍", "🥝", "🍒", "🍐"]),
        ("Vegetables", ["🥦", "🥕", "🌽", "🥑", "🍅", "🥬", "🧅", "🧄", "🥔", "🫑", "🥒", "🌶️", "🍄"]),
        ("Meat & Fish", ["🍗", "🥩", "🥓", "🍖", "🦐", "🐟", "🦑", "🦞", "🦀", "🥚", "🍣", "🦪"]),
        ("Dairy & Grains", ["🧀", "🥛", "🍞", "🥐", "🧈", "🌾", "🥣", "🫙", "🥫", "🧆", "🫔"]),
        ("Snacks & Pantry", ["🍫", "🍪", "🍿", "🥜", "🌰", "🍯", "🧂", "🫒", "🧁", "🍰", "🫘"]),
        ("Drinks", ["☕", "🍵", "🧃", "🥤", "🍷", "🍺", "🧋", "💧", "🫖", "🍹", "🥂"]),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(selectedEmoji.isEmpty ? "🍽️" : selectedEmoji)
                        .font(.system(size: 72))
                        .frame(width: 100, height: 100)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Custom emoji")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        HStack {
                            TextField("Type or paste an emoji…", text: $customInput)
                                .font(.system(size: 24))
                                .onChange(of: customInput) { _, newValue in
                                    guard !newValue.isEmpty else { return }
                                    let first = String(newValue.prefix(1))
                                    if first != customInput { customInput = first }
                                    selectedEmoji = first
                                }

                            if !customInput.isEmpty {
                                Button {
                                    customInput = ""
                                    selectedEmoji = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                        if #available(iOS 26, *) {
                            Text("Tip: Open the emoji keyboard to generate a custom Genmoji ✨")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }
                    }

                    ForEach(emojiGroups, id: \.0) { group, emojis in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(emojis, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        customInput = emoji
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 40, height: 40)
                                            .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if !selectedEmoji.isEmpty {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear") {
                            selectedEmoji = ""
                            customInput = ""
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            customInput = selectedEmoji
        }
    }
}

#Preview {
    EditFoodView()
}
