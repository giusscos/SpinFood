import SwiftUI
import SwiftData

struct FoodDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: FoodModel

    @State private var showEdit = false
    @State private var showConsume = false
    @State private var appeared = false

    @Namespace private var editNamespace

    private var displayEmoji: String {
        food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
    }

    private var stockColor: Color {
        if food.isOutOfStock { return .red }
        if food.isLowStock { return .orange }
        return .green
    }

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
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
                    heroSection

                    divider

                    stockSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    if food.expiryDate != nil {
                        divider
                        expirySection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(paperBackground.ignoresSafeArea())
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        if #available(iOS 26, *) {
                            Label("Close", systemImage: "xmark")
                        } else {
                            Label("Close", systemImage: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, .gray)
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .matchedTransitionSource(id: "editFood", in: editNamespace)
                    
                    if #available(iOS 26, *) {
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                modelContext.delete(food)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    } else {
                        Button(role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                modelContext.delete(food)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionBar
            }
            .sheet(isPresented: $showEdit) {
                EditFoodView(food: food)
                    .navigationTransition(.zoom(sourceID: "editFood", in: editNamespace))
            }
            .sheet(isPresented: $showConsume) {
                FoodConsumeSheet(food: food)
            }
            .onAppear {
                withAnimation(.spring(duration: 0.45, bounce: 0.25).delay(0.06)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var heroSection: some View {
        VStack(spacing: 14) {
            Text(displayEmoji)
                .font(.system(size: 62))

            VStack(spacing: 6) {
                Text(food.name)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .multilineTextAlignment(.center)

                Label(food.category.rawValue, systemImage: food.category.icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
    }

    private var stockSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(food.currentQuantity, format: .number)
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(stockColor)

                Text("/")
                    .font(.system(.title2, design: .rounded))
                    .foregroundStyle(.tertiary)

                Text(food.quantity, format: .number)
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)

                Text(food.unit.abbreviation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if food.isOutOfStock {
                Label("Out of stock", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline.weight(.medium))
            } else if food.isLowStock {
                Label("Low stock", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline.weight(.medium))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var expirySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Expiry", systemImage: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                if let expiry = food.expiryDate {
                    Text(expiry, style: .date)
                        .font(.body)
                }
                Spacer()
                if food.isExpired {
                    Label("Expired", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline.weight(.medium))
                } else if food.isExpiringSoon {
                    Label("Expiring soon", systemImage: "clock.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline.weight(.medium))
                } else if let days = food.daysUntilExpiry {
                    Text("\(days) days left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                showConsume = true
            } label: {
                Label("Eat", systemImage: "fork.knife")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .tint(.accent)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(food.isOutOfStock)

            Button {
                refill()
            } label: {
                Label("Refill", systemImage: "arrow.trianglehead.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .tint(.blue)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(food.currentQuantity >= food.quantity)
        }
        .padding()
        .background(.thinMaterial)
    }

    // MARK: - Actions

    private func refill() {
        let needed = food.quantity - food.currentQuantity
        guard needed > 0 else { return }
        let record = FoodRefillModel(quantity: needed, unit: food.unit, food: food)
        modelContext.insert(record)
        food.currentQuantity = food.quantity
    }
}

// MARK: - Consume Sheet

private struct FoodConsumeSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    var food: FoodModel

    @State private var amount: Decimal = 1

    private var displayEmoji: String {
        food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Text(displayEmoji)
                        .font(.system(size: 48))

                    Text(food.name)
                        .font(.system(.title3, design: .serif).weight(.semibold))

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(food.currentQuantity, format: .number)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(food.isOutOfStock ? .red : food.isLowStock ? .orange : .green)
                        Text(food.unit.abbreviation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                Divider().padding(.horizontal)

                QuantityTickerPicker(value: $amount, unit: food.unit, maxValue: food.currentQuantity)
                    .padding(14)
                    .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
            }
            .padding(.bottom, 16)
            .navigationTitle("How much did you eat?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .cancel) { dismiss() } label: {
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
                    if #available(iOS 26, *) {
                        Button(role: .confirm) {
                            logConsumption()
                            dismiss()
                        } label: {
                            Label("Log", systemImage: "checkmark")
                        }
                        .disabled(amount <= 0)
                    } else {
                        Button {
                            logConsumption()
                            dismiss()
                        } label: {
                            Label("Log", systemImage: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.background, amount <= 0 ? .gray : .accent)
                        }
                        .disabled(amount <= 0)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func logConsumption() {
        let actual = min(amount, food.currentQuantity)
        guard actual > 0 else { return }
        let record = FoodConsumptionModel(quantity: actual, unit: food.unit, food: food)
        modelContext.insert(record)
        food.currentQuantity = max(0, food.currentQuantity - actual)
    }
}
