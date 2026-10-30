import SwiftUI
import SwiftData

/// The fast way to stock the pantry: tap everything you bought, then add it all at once.
/// Quantity, unit, category and expiry start from sensible defaults and can be changed in the tray.
struct QuickAddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var foods: [FoodModel]

    private enum ActiveSheet: Identifiable {
        case custom(String)
        case scanned(OpenFoodFactsProduct)
        case editPick(String)

        var id: String {
            switch self {
            case .custom(let name): return "custom-\(name)"
            case .scanned(let product): return "scanned-\(product.barcode)"
            case .editPick(let itemID): return "edit-\(itemID)"
            }
        }
    }

    @State private var picks: [GroceryPick] = []
    @State private var searchText = ""
    @State private var activeSheet: ActiveSheet?
    @State private var showBarcodeScanner = false
    @State private var isLookingUpBarcode = false
    @State private var barcodeLookupError: String?

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var searchResults: [GroceryItem] {
        GroceryCatalog.all.filter { $0.matches(search: trimmedSearch) }
    }

    /// Groceries in the pantry that are running out, or that a recipe needs, for the weekly top-up.
    private var suggestedRestock: [GroceryItem] {
        var seen = Set<String>()
        return foods
            .filter { $0.stockPercentage < 0.5 }
            .sorted { $0.stockPercentage < $1.stockPercentage }
            .compactMap { GroceryCatalog.item(matching: $0.name) }
            .filter { seen.insert($0.id).inserted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if trimmedSearch.isEmpty {
                        browseContent
                    } else {
                        searchContent
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            // Ready for the next item as soon as one is picked from the results.
            .onChange(of: picks.count) { _, _ in
                if !trimmedSearch.isEmpty { searchText = "" }
            }
            .background(paperBackground.ignoresSafeArea())
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search groceries"
            )
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        if #available(iOS 26, *) {
                            Label("Cancel", systemImage: "xmark")
                        } else {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .gray)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isLookingUpBarcode {
                        ProgressView()
                    } else {
                        Button {
                            showBarcodeScanner = true
                        } label: {
                            Label("Barcode scanner", systemImage: "barcode.viewfinder")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !picks.isEmpty {
                    tray
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .custom(let name):
                    EditFoodView(prefilledName: name, onSaved: customFoodSaved)
                case .scanned(let product):
                    EditFoodView(scannedProduct: product, onSaved: customFoodSaved)
                case .editPick(let itemID):
                    pickEditor(itemID: itemID)
                }
            }
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                BarcodeScannerView(
                    onScan: { code in
                        showBarcodeScanner = false
                        Task { await handleScannedBarcode(code) }
                    },
                    onCancel: { showBarcodeScanner = false }
                )
                .ignoresSafeArea()
            }
            .alert("Barcode Lookup", isPresented: Binding(
                get: { barcodeLookupError != nil },
                set: { if !$0 { barcodeLookupError = nil } }
            )) {
                Button("OK", role: .cancel) {}
                Button("Add Manually") { activeSheet = .custom("") }
            } message: {
                Text(barcodeLookupError ?? "")
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var browseContent: some View {
        customFoodButton(name: "")

        if !suggestedRestock.isEmpty {
            section(title: "You may need", systemImage: "arrow.trianglehead.counterclockwise", items: suggestedRestock)
        }

        ForEach(FoodCategory.allCases, id: \.self) { category in
            let items = GroceryCatalog.all.filter { $0.category == category }
            if !items.isEmpty {
                section(title: LocalizedStringKey(category.rawValue), systemImage: category.icon, items: items)
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if !searchResults.isEmpty {
            GroceryGrid(items: searchResults, picks: $picks, foods: foods)
        }
        if GroceryCatalog.item(matching: trimmedSearch) == nil {
            customFoodButton(name: trimmedSearch)
        }
    }

    private func section(title: LocalizedStringKey, systemImage: String, items: [GroceryItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            GroceryGrid(items: items, picks: $picks, foods: foods)
        }
    }

    private func customFoodButton(name: String) -> some View {
        Button {
            activeSheet = .custom(name)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.pencil")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                Group {
                    if name.isEmpty {
                        Text("Something else? Add it by hand")
                    } else {
                        Text("Add \"\(name)\"")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tray

    private var tray: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(picks) { pick in
                        Button {
                            activeSheet = .editPick(pick.id)
                        } label: {
                            HStack(spacing: 5) {
                                Text(pick.item.emoji)
                                Text("\(pick.quantity.formatted()) \(pick.item.unit.abbreviation)")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.secondary.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button {
                GroceryCatalog.stock(picks, foods: foods, in: modelContext)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            } label: {
                Text("Add \(picks.count) to Inventory")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(.bar)
    }

    @ViewBuilder
    private func pickEditor(itemID: String) -> some View {
        if let current = picks.first(where: { $0.id == itemID }) {
            GroceryPickEditor(
                pick: Binding(
                    get: { picks.first { $0.id == itemID } ?? current },
                    set: { edited in
                        if let index = picks.firstIndex(where: { $0.id == itemID }) { picks[index] = edited }
                    }
                ),
                onRemove: {
                    picks.removeAll { $0.id == itemID }
                    activeSheet = nil
                }
            )
        }
    }

    /// Done if that was the only thing to add; otherwise back to the groceries still in the tray.
    private func customFoodSaved() {
        searchText = ""
        if picks.isEmpty { dismiss() }
    }

    // MARK: - Barcode

    @MainActor
    private func handleScannedBarcode(_ code: String) async {
        isLookingUpBarcode = true
        defer { isLookingUpBarcode = false }
        do {
            activeSheet = .scanned(try await OpenFoodFactsService.lookup(barcode: code))
        } catch {
            barcodeLookupError = error.localizedDescription
        }
    }
}

// MARK: - Grid

/// Tappable grocery tiles. Tapping toggles an item in `picks`.
struct GroceryGrid: View {
    let items: [GroceryItem]
    @Binding var picks: [GroceryPick]
    let foods: [FoodModel]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                let pick = picks.first { $0.id == item.id }
                Button {
                    toggle(item)
                } label: {
                    GroceryTile(item: item, pick: pick, pantryFood: item.pantryFood(in: foods))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: pick != nil)
            }
        }
    }

    private func toggle(_ item: GroceryItem) {
        withAnimation(.snappy(duration: 0.2)) {
            if let index = picks.firstIndex(where: { $0.id == item.id }) {
                picks.remove(at: index)
            } else {
                picks.append(GroceryPick(item: item))
            }
        }
    }
}

private struct GroceryTile: View {
    let item: GroceryItem
    let pick: GroceryPick?
    let pantryFood: FoodModel?

    private var isSelected: Bool { pick != nil }

    var body: some View {
        VStack(spacing: 4) {
            Text(item.emoji)
                .font(.system(size: 30))
                .frame(height: 36)

            Text(item.name)
                .font(.system(.footnote, design: .serif).weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            caption
                .font(.system(.caption2, design: .rounded))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08),
            in: .rect(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .padding(5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(.rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var caption: some View {
        if let pick {
            Text("+\(pick.quantity.formatted()) \(item.unit.abbreviation)")
                .foregroundStyle(Color.accentColor)
                .fontWeight(.semibold)
        } else if let pantryFood, !pantryFood.isOutOfStock {
            Text("Have \(pantryFood.currentQuantity.formatted()) \(pantryFood.unit.abbreviation)")
                .foregroundStyle(.secondary)
        } else {
            Text("\(item.packQuantity.formatted()) \(item.unit.abbreviation)")
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Pick editor

private struct GroceryPickEditor: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var pick: GroceryPick
    var onRemove: () -> Void

    private var hasExpiry: Binding<Bool> {
        Binding(
            get: { pick.expiryDate != nil },
            set: { isOn in
                pick.expiryDate = isOn
                    ? (pick.item.suggestedExpiry ?? Calendar.current.date(byAdding: .day, value: 7, to: .now))
                    : nil
            }
        )
    }

    private var expiry: Binding<Date> {
        Binding(
            get: { pick.expiryDate ?? .now },
            set: { pick.expiryDate = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    QuantityTickerPicker(value: $pick.quantity, unit: pick.item.unit)
                        .padding(12)
                        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))

                    Toggle("Track expiry date", isOn: hasExpiry)

                    if pick.expiryDate != nil {
                        DatePicker(
                            "Expires on",
                            selection: expiry,
                            in: Date.now...,
                            displayedComponents: .date
                        )
                    }

                    Button(role: .destructive, action: onRemove) {
                        Label("Remove", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
                .padding()
            }
            .navigationTitle("\(pick.item.emoji) \(pick.item.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    QuickAddFoodView()
}
