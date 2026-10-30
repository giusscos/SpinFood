import SwiftUI
import SwiftData

struct EditFoodView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: FoodModel?
    var scannedProduct: OpenFoodFactsProduct? = nil
    var prefilledName: String = ""
    /// Runs after a new or edited food is saved, on top of closing this sheet.
    var onSaved: (() -> Void)? = nil

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var quantity: Decimal = 1
    @State private var currentQuantity: Decimal = 0
    @State private var unit: FoodUnit = .piece
    @State private var category: FoodCategory = .other
    @State private var hasExpiryDate: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var showEmojiPicker: Bool = false
    @State private var showBarcodeScanner: Bool = false
    @State private var isLookingUpBarcode: Bool = false
    @State private var barcodeError: String? = nil
    @State private var scannedBarcodeHint: String? = nil
    @State private var productImageURL: URL? = nil
    /// The catalog item whose defaults were last applied, so later manual changes aren't overwritten.
    @State private var autofilledItemID: String? = nil

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
                    // Food details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Food details", systemImage: "tag")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if !isEditing {
                                Button {
                                    focusedField = nil
                                    barcodeError = nil
                                    showBarcodeScanner = true
                                } label: {
                                    Label("Scan", systemImage: "barcode.viewfinder")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }

                        if isLookingUpBarcode {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Looking up product…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if scannedBarcodeHint != nil || productImageURL != nil {
                            HStack(alignment: .center, spacing: 10) {
                                if let productImageURL {
                                    AsyncImage(url: productImageURL) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 52, height: 52)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.secondary.opacity(0.1))
                                                .frame(width: 52, height: 52)
                                                .overlay { ProgressView().scaleEffect(0.7) }
                                        }
                                    }
                                }
                                if let scannedBarcodeHint {
                                    Text(scannedBarcodeHint)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if let barcodeError {
                            Text(barcodeError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        HStack(spacing: 12) {
                            Button {
                                focusedField = nil
                                showEmojiPicker = true
                            } label: {
                                Text(emoji.isEmpty ? category.defaultEmoji : emoji)
                                    .font(.system(size: 26))
                                    .frame(width: 44, height: 44)
                                    .background(.secondary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Food emoji")

                            TextField("Name", text: $name)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .name)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                                .onChange(of: name) { _, newName in
                                    applyCatalogDefaults(for: newName)
                                }
                        }

                        Divider()

                        HStack {
                            Text("Category")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $category) {
                                ForEach(FoodCategory.allCases, id: \.self) { cat in
                                    Label(cat.localizedName, systemImage: cat.icon).tag(cat)
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
                                    Text(u.localizedName).tag(u)
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
                } else if let scannedProduct {
                    apply(scannedProduct)
                } else if !prefilledName.isEmpty {
                    name = prefilledName
                    applyCatalogDefaults(for: prefilledName)
                }
            }
            .sheet(isPresented: $showEmojiPicker) {
                EmojiPickerSheet(selectedEmoji: $emoji)
            }
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    onScan: { code in
                        showBarcodeScanner = false
                        Task { await lookupBarcode(code) }
                    },
                    onCancel: { showBarcodeScanner = false }
                )
                .ignoresSafeArea()
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

        modelContext.saveConfirmedChanges()
        dismiss()
        onSaved?()
    }

    /// Fills unit, amount, category, emoji and expiry when the typed name is a known grocery.
    private func applyCatalogDefaults(for typedName: String) {
        guard !isEditing, scannedProduct == nil,
              let item = GroceryCatalog.item(matching: typedName),
              item.id != autofilledItemID else { return }
        autofilledItemID = item.id
        emoji = item.emoji
        category = item.category
        unit = item.unit
        quantity = item.packQuantity
        if let expiry = item.suggestedExpiry {
            hasExpiryDate = true
            expiryDate = expiry
        }
    }

    private func apply(_ product: OpenFoodFactsProduct) {
        name = product.name
        emoji = product.emoji
        category = product.category
        unit = product.unit
        productImageURL = product.imageURL
        if quantity == 0 {
            if let parsed = product.parsedQuantity, parsed > 0 {
                quantity = parsed
            } else {
                quantity = unit == .piece ? 1 : 100
            }
        }
        var hint = String(localized: "Scanned: \(product.barcode)")
        if let brand = product.brand, !brand.isEmpty {
            hint += " · \(brand)"
        }
        scannedBarcodeHint = hint
    }

    @MainActor
    private func lookupBarcode(_ code: String) async {
        isLookingUpBarcode = true
        barcodeError = nil
        productImageURL = nil
        defer { isLookingUpBarcode = false }
        do {
            let product = try await OpenFoodFactsService.lookup(barcode: code)
            apply(product)
        } catch {
            barcodeError = error.localizedDescription
            scannedBarcodeHint = String(localized: "Barcode: \(code)")
        }
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
