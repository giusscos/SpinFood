import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    @State private var step: Int = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            switch step {
            case 0:
                OnboardingWelcomeView(onNext: advance)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 1:
                OnboardingAddFoodView(onNext: advance, onSkip: completeOnboarding)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                OnboardingAddRecipeView(onNext: completeOnboarding, onSkip: completeOnboarding)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private func advance() { step += 1 }

    private func completeOnboarding() { onboardingCompleted = true }
}

// MARK: - Welcome Step

struct OnboardingWelcomeView: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    Text("Welcome to SpinFood")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Track what's in your pantry, plan your meals, and never buy ingredients you already have.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                OnboardingFeatureRow(icon: "leaf.fill", color: .green, title: "Reduce food waste", description: "Know what you have before buying more")
                OnboardingFeatureRow(icon: "cart.fill", color: .blue, title: "Shop smarter", description: "Generate shopping lists from your recipes")
                OnboardingFeatureRow(icon: "chart.bar.fill", color: .orange, title: "Track habits", description: "See what you consume and when")
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Add Food Step

struct OnboardingAddFoodView: View {
    @Environment(\.modelContext) var modelContext

    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var name: String = ""
    @State private var quantity: Decimal? = nil
    @State private var unit: FoodUnit = .gram
    @State private var category: FoodCategory = .produce
    @State private var isSaved: Bool = false

    @FocusState private var focusedField: Bool

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (quantity ?? 0) > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "carrot.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                    }

                    Text("Add your first food")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Tell SpinFood what's in your pantry. You can add more later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                GroupBox {
                    VStack(spacing: 16) {
                        TextField("e.g. Pasta, Tomatoes, Milk…", text: $name)
                            .font(.body)
                            .focused($focusedField)
                            .autocorrectionDisabled()
                            .submitLabel(.done)

                        Divider()

                        Picker("Category", selection: $category) {
                            ForEach(FoodCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Quantity")
                            Spacer()
                            TextField("0", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Picker("", selection: $unit) {
                                ForEach(FoodUnit.allCases, id: \.self) { u in
                                    Text(u.abbreviation).tag(u)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                    .padding(4)
                } label: {
                    Text("Food details")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if isSaved {
                    Label("Food saved!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .transition(.scale.combined(with: .opacity))
                }

                VStack(spacing: 12) {
                    Button(action: saveAndContinue) {
                        Text(isSaved ? "Continue" : "Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave || isSaved ? Color.accentColor : Color.secondary.opacity(0.3))
                            .foregroundStyle(canSave || isSaved ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canSave && !isSaved)

                    Button("Skip for now", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .animation(.spring(duration: 0.3), value: isSaved)
        .onAppear { focusedField = true }
    }

    private func saveAndContinue() {
        if isSaved { onNext(); return }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, let qty = quantity, qty > 0 else { return }

        let food = FoodModel(name: trimmedName, quantity: qty, currentQuantity: qty, unit: unit, category: category)
        modelContext.insert(food)
        isSaved = true
        focusedField = false
    }
}

// MARK: - Add Recipe Step

struct OnboardingAddRecipeView: View {
    @Environment(\.modelContext) var modelContext

    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var name: String = ""
    @State private var isSaved: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                    }

                    Text("Name your first recipe")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Name a dish you cook regularly. Add ingredients and steps later from the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                GroupBox {
                    TextField("e.g. Spaghetti Bolognese…", text: $name)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(4)
                } label: {
                    Text("Recipe name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if isSaved {
                    Label("Recipe saved!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .transition(.scale.combined(with: .opacity))
                }

                VStack(spacing: 12) {
                    Button(action: saveAndContinue) {
                        Text(isSaved ? "Finish Setup" : "Save & Finish")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(!name.trimmingCharacters(in: .whitespaces).isEmpty || isSaved ? Color.accentColor : Color.secondary.opacity(0.3))
                            .foregroundStyle(!name.trimmingCharacters(in: .whitespaces).isEmpty || isSaved ? .white : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaved)

                    Button("Skip for now", action: onSkip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .animation(.spring(duration: 0.3), value: isSaved)
        .onAppear { focused = true }
    }

    private func saveAndContinue() {
        if isSaved { onNext(); return }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let recipe = RecipeModel(name: trimmedName)
        modelContext.insert(recipe)
        isSaved = true
        focused = false
    }
}
