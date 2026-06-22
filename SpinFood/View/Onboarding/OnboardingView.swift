import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) var modelContext
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    @State private var step: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                ZStack {
                    switch step {
                    case 0:
                        OnboardingWelcomeView(onNext: advance)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 1:
                        OnboardingAddFoodView(onNext: advance, onSkip: completeOnboarding)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case 2:
                        OnboardingAddRecipeView(onNext: completeOnboarding, onSkip: completeOnboarding)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                Capsule()
                    .fill(step == i ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: step == i ? 20 : 7, height: 7)
                    .animation(.spring(duration: 0.4), value: step)
            }
        }
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

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(Color.accentColor.opacity(0.07))
                        .frame(width: 160, height: 160)
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 12) {
                    Text("Welcome to SpinFood")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Track your pantry, plan your meals,\nand reduce food waste every day.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 14) {
                OnboardingFeatureRow(icon: "leaf.fill", color: .green,
                    title: "Reduce food waste",
                    description: "Know what you have before buying more")
                OnboardingFeatureRow(icon: "cart.fill", color: .blue,
                    title: "Shop smarter",
                    description: "Generate shopping lists from your recipes")
                OnboardingFeatureRow(icon: "chart.bar.fill", color: .orange,
                    title: "Track habits",
                    description: "See what you consume and when")
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)

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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Image(systemName: "carrot.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 8)

                    Text("Add your first food")
                        .font(.title2.bold())

                    Text("Tell SpinFood what's in your pantry.\nYou can always add more later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal)
                }

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        TextField("Name (e.g. Pasta, Tomatoes…)", text: $name)
                            .focused($focusedField)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))

                    Divider().padding(.leading, 52)

                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Picker("Category", selection: $category) {
                            ForEach(FoodCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))

                    Divider().padding(.leading, 52)

                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text("Quantity")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Picker("", selection: $unit) {
                            ForEach(FoodUnit.allCases, id: \.self) { u in
                                Text(u.abbreviation).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                if isSaved {
                    Label("Saved to your pantry!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.medium))
                        .transition(.scale.combined(with: .opacity))
                }

                VStack(spacing: 10) {
                    Button(action: saveAndContinue) {
                        Text(isSaved ? "Continue" : "Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canSave || isSaved ? Color.accentColor : Color.secondary.opacity(0.25))
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

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let qty = quantity, qty > 0 else { return }

        let food = FoodModel(name: trimmed, quantity: qty, currentQuantity: qty, unit: unit, category: category)
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Image(systemName: "fork.knife")
                            .font(.system(size: 42))
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 8)

                    Text("Name your first recipe")
                        .font(.title2.bold())

                    Text("What dish do you cook most often?\nYou can add ingredients and steps later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal)
                }

                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    TextField("e.g. Spaghetti Bolognese…", text: $name)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                if isSaved {
                    Label("Recipe added to your book!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.weight(.medium))
                        .transition(.scale.combined(with: .opacity))
                }

                VStack(spacing: 10) {
                    Button(action: saveAndContinue) {
                        Text(isSaved ? "Finish Setup" : "Save & Finish")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(!name.trimmingCharacters(in: .whitespaces).isEmpty || isSaved ? Color.accentColor : Color.secondary.opacity(0.25))
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

        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let recipe = RecipeModel(name: trimmed)
        modelContext.insert(recipe)
        isSaved = true
        focused = false
    }
}
