import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: FoodModel?

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var quantity: Decimal = 0
    @State private var currentQuantity: Decimal = 0
    @State private var unit: FoodUnit = .gram
    @State private var category: FoodCategory = .other
    @State private var hasExpiryDate: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var showEmojiPicker: Bool = false

    enum Field: Hashable {
        case name
    }

    @FocusState private var focusedField: Field?

    var isEditing: Bool { food != nil }

    private var paperBackground: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    private var divider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Emoji
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Emoji", systemImage: "face.smiling")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Button {
                            focusedField = nil
                            showEmojiPicker = true
                        } label: {
                            HStack(spacing: 14) {
                                Text(emoji.isEmpty ? category.defaultEmoji : emoji)
                                    .font(.system(size: 30))
                                    .frame(width: 48, height: 48)
                                    .background(.secondary.opacity(0.1))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Food emoji")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(emoji.isEmpty ? "None selected" : "Custom emoji set")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding()

                    divider

                    // Food details
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Food details", systemImage: "tag")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField("Name", text: $name)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .name)
                            .submitLabel(.done)
                            .onSubmit { focusedField = nil }

                        Divider()

                        HStack {
                            Text("Category")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $category) {
                                ForEach(FoodCategory.allCases, id: \.self) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        Divider()

                        HStack {
                            Text("Unit")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $unit) {
                                ForEach(FoodUnit.allCases, id: \.self) { u in
                                    Text(u.rawValue).tag(u)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    }
                    .padding()

                    divider

                    // Quantity
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Stock quantity", systemImage: "scalemass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        QuantityTickerPicker(value: $quantity, unit: unit)
                            .padding(12)
                            .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))

                        if isEditing {
                            Label("Current quantity", systemImage: "cart")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)

                            QuantityTickerPicker(value: $currentQuantity, unit: unit)
                                .padding(12)
                                .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding()

                    divider

                    // Expiry date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Expiry date", systemImage: "calendar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Toggle("Track expiry date", isOn: $hasExpiryDate)

                        if hasExpiryDate {
                            Divider()

                            DatePicker(
                                "Expires on",
                                selection: $expiryDate,
                                in: Date.now...,
                                displayedComponents: .date
                            )
                        }
                    }
                    .padding()

                    Spacer(minLength: 40)
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Food" : "Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if #available(iOS 26, *) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    } else {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .gray)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            saveFood()
                        } label: {
                            Label("Save", systemImage: "checkmark")
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    } else {
                        Button {
                            saveFood()
                        } label: {
                            Label("Save", systemImage: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, name.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .accent)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    Button {
                        hideKeyboard()
                    } label: {
                        Label("Hide Keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
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

#if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
#endif

    private func saveFood() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let food {
            food.name = trimmedName
            food.emoji = emoji
            food.category = category
            food.unit = unit
            food.expiryDate = hasExpiryDate ? expiryDate : nil
            food.quantity = quantity
            food.currentQuantity = currentQuantity
        } else {
            let newFood = FoodModel(
                name: trimmedName,
                emoji: emoji,
                quantity: quantity,
                currentQuantity: quantity,
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
