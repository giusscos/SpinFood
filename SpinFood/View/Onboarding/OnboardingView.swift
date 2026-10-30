import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false
    @Environment(Store.self) private var store

    @State private var step: Int = 0
    @State private var stockedPicks: [GroceryPick] = []
    @State private var notificationStatus: UNAuthorizationStatus?

    // Kept short so people reach their recipe book quickly. Alarms are requested when the
    // first cook timer starts.
    private static let remindersStep = 2
    private static let paywallStep = 3

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                if step < Self.paywallStep {
                    stepIndicator
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                }

                ZStack {
                    switch step {
                    case 0:
                        OnboardingWelcomeView(onNext: advance)
                            .transition(stepTransition)
                    case 1:
                        OnboardingKitchenView { picks in
                            stockedPicks = picks
                            // The system only asks once, so there's nothing to offer after a reinstall that kept the answer.
                            let canAsk = notificationStatus == nil || notificationStatus == .notDetermined
                            step = canAsk ? Self.remindersStep : Self.paywallStep
                        }
                        .transition(stepTransition)
                    case Self.remindersStep:
                        OnboardingRemindersView(picks: stockedPicks, onNext: advance)
                            .transition(stepTransition)
                    default:
                        PaywallView(context: .onboarding, onClose: completeOnboarding)
                            .environment(store)
                            .transition(stepTransition)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
        // Read up front so leaving the kitchen step is instant: a delay there invites a second tap.
        .task {
            notificationStatus = await NotificationManager.shared.authorizationStatus()
        }
    }

    private var stepTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.96))
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.paywallStep, id: \.self) { i in
                Capsule()
                    .fill(step == i ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: step == i ? 20 : 7, height: 7)
                    .animation(.spring(duration: 0.4), value: step)
            }
        }
    }

    private func advance() { step = min(step + 1, Self.paywallStep) }

    private func completeOnboarding() { onboardingCompleted = true }
}

// MARK: - Welcome Step

struct OnboardingWelcomeView: View {
    let onNext: () -> Void
    @State private var appeared = false
    @State private var dishesAppeared = false
    @State private var row1Appeared = false
    @State private var row2Appeared = false
    @State private var row3Appeared = false
    @State private var buttonAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Fills the screen when it fits, and scrolls at large text sizes or on short screens.
            ViewThatFits(in: .vertical) {
                welcomeContent
                ScrollView { welcomeContent }
            }

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
            .frame(maxWidth: 480)
            .padding(.bottom, 48)
            .opacity(buttonAppeared ? 1 : 0)
            .blur(radius: buttonAppeared ? 0 : 6)
            .scaleEffect(buttonAppeared ? 1 : 0.88)
        }
        .onAppear {
            dishesAppeared = true
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.35)) { appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.55)) { row1Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.68)) { row2Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.81)) { row3Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.98)) { buttonAppeared = true }
        }
    }

    private var welcomeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                OnboardingDishCluster(appeared: dishesAppeared)

                VStack(spacing: 12) {
                    Text("Cook what you have")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Your recipes and pantry in one book,\nso you always know what's for dinner.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    HStack(spacing: 5) {
                        Image(systemName: "trash.slash.fill")
                            .font(.caption2)
                        Text("1 in 3 groceries goes to waste.")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.1), in: Capsule())
                }
                .opacity(appeared ? 1 : 0)
                .blur(radius: appeared ? 0 : 12)
                .offset(y: appeared ? 0 : 16)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "frying.pan.fill",
                    color: .green,
                    title: String(localized: "Cook from your pantry"),
                    description: String(localized: "See which recipes you can make right now")
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "cart.fill.badge.plus",
                    color: .blue,
                    title: String(localized: "Stock up in seconds"),
                    description: String(localized: "Tap what you bought or scan the barcode")
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "leaf.fill",
                    color: .orange,
                    title: String(localized: "Waste less"),
                    description: String(localized: "Get a nudge before food expires")
                )
                .opacity(row3Appeared ? 1 : 0)
                .blur(radius: row3Appeared ? 0 : 8)
                .offset(y: row3Appeared ? 0 : 18)
                .scaleEffect(row3Appeared ? 1 : 0.94, anchor: .leading)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)

            Spacer()
        }
    }
}

// MARK: - Dish Cluster

private struct OnboardingDishItem: Identifiable {
    let id: String
    let imageName: String
    let size: CGFloat
    let restingOffset: CGSize
    let entryOffset: CGSize
    let rotation: Double
    let delay: Double
}

private struct OnboardingDishCluster: View {
    let appeared: Bool

    private let dishes: [OnboardingDishItem] = [
        .init(
            id: "salad",
            imageName: "OnboardingDishSalad",
            size: 100,
            restingOffset: CGSize(width: -58, height: -52),
            entryOffset: CGSize(width: -280, height: -220),
            rotation: -12,
            delay: 0
        ),
        .init(
            id: "pasta",
            imageName: "OnboardingDishPasta",
            size: 108,
            restingOffset: CGSize(width: 58, height: -56),
            entryOffset: CGSize(width: 280, height: -240),
            rotation: 10,
            delay: 0.1
        ),
        .init(
            id: "pizza",
            imageName: "OnboardingDishPizza",
            size: 96,
            restingOffset: CGSize(width: -52, height: 54),
            entryOffset: CGSize(width: -260, height: 240),
            rotation: -8,
            delay: 0.2
        ),
        .init(
            id: "soup",
            imageName: "OnboardingDishSoup",
            size: 102,
            restingOffset: CGSize(width: 54, height: 50),
            entryOffset: CGSize(width: 270, height: 230),
            rotation: 14,
            delay: 0.3
        ),
    ]

    /// Layout size that fully contains every dish at its resting position (plus shadow).
    private var clusterSize: CGSize {
        var minX: CGFloat = 0
        var maxX: CGFloat = 0
        var minY: CGFloat = 0
        var maxY: CGFloat = 0
        let shadowPad: CGFloat = 12

        for dish in dishes {
            let half = dish.size / 2
            minX = min(minX, dish.restingOffset.width - half)
            maxX = max(maxX, dish.restingOffset.width + half)
            minY = min(minY, dish.restingOffset.height - half)
            maxY = max(maxY, dish.restingOffset.height + half)
        }

        return CGSize(
            width: maxX - minX + shadowPad * 2,
            height: maxY - minY + shadowPad * 2
        )
    }

    var body: some View {
        ZStack {
            ForEach(dishes) { dish in
                Image(dish.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: dish.size, height: dish.size)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.9), lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                    .rotationEffect(.degrees(appeared ? dish.rotation : dish.rotation * 2.5))
                    .offset(appeared ? dish.restingOffset : dish.entryOffset)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(duration: 0.95, bounce: 0.58).delay(dish.delay),
                        value: appeared
                    )
            }
        }
        .frame(width: clusterSize.width, height: clusterSize.height)
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

// MARK: - Kitchen Step

/// Gets real food into the pantry before the first look at the book, so recipe ideas
/// can show what's cookable right away.
struct OnboardingKitchenView: View {
    let onNext: ([GroceryPick]) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var foods: [FoodModel]

    @State private var picks: [GroceryPick] = []

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    Text("What's in your kitchen?")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text("Tap what you have. Foo fills in amounts and expiry dates, and you can change them anytime.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .padding(.bottom, 16)

                GroceryGrid(items: GroceryCatalog.essentials, picks: $picks, foods: foods)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 640)
            }

            Button(action: finish) {
                Group {
                    if picks.isEmpty {
                        Text("Skip for now")
                    } else {
                        Text("Add \(picks.count) to Inventory")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(picks.isEmpty ? Color.secondary.opacity(0.15) : Color.accentColor)
                .foregroundStyle(picks.isEmpty ? Color.primary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    private func finish() {
        GroceryCatalog.stock(picks, foods: foods, in: modelContext)
        onNext(picks)
    }
}

// MARK: - Reminders Step

/// Explains the reminders before the system's one-time prompt, using the food just added.
/// "Not now" leaves that prompt unspent, so the inventory can offer it again later.
struct OnboardingRemindersView: View {
    let picks: [GroceryPick]
    let onNext: () -> Void

    @AppStorage(ReminderSchedule.storageKey) private var reminderMinutes = ReminderSchedule.beforeDinner
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var appeared = false
    @State private var isAsking = false

    /// The food that expires first, or everyday examples for anyone who skipped the kitchen step.
    private var previewItems: [GroceryItem] {
        let soonest = picks
            .filter { $0.expiryDate != nil }
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
            .map(\.item)
        let examples = ["spinach", "milk"].compactMap { GroceryCatalog.item(id: $0) }
        return Array((soonest + examples.filter { !soonest.contains($0) }).prefix(2))
    }

    private var fireTime: String {
        let today = Calendar.current.startOfDay(for: .now)
        let minutes = max(reminderMinutes, 0)
        let time = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: today) ?? today
        return time.formatted(date: .omitted, time: .shortened)
    }

    private func recipeName(for item: GroceryItem) -> String? {
        StarterRecipe.all.first { recipe in recipe.ingredients.contains { $0.id == item.id } }?.localizedName
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fills the screen when it fits, and scrolls at large text sizes or on short screens.
            ViewThatFits(in: .vertical) {
                explanation
                ScrollView { explanation }
            }

            VStack(spacing: 10) {
                Button(action: turnOn) {
                    Text("Turn On Reminders")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isAsking)

                Button("Not now", action: onNext)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: 480)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.25).delay(0.1)) { appeared = true }
        }
    }

    private var explanation: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Text("Know what to use first")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("A heads-up before food expires, with a recipe that uses it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer(minLength: 16)

            notificationPreview
                .padding(.horizontal, 20)
                .frame(maxWidth: 480)

            Spacer(minLength: 16)

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "bell.badge.fill",
                    color: .orange,
                    title: String(localized: "One reminder a day, at most"),
                    description: String(localized: "Only when there's something worth telling you")
                )
                OnboardingFeatureRow(
                    icon: "leaf.fill",
                    color: .green,
                    title: String(localized: "About your food, nothing else"),
                    description: String(localized: "No ads or offers, ever")
                )
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .opacity(appeared ? 1 : 0)

            Spacer(minLength: 16)

            VStack(alignment: .leading, spacing: 8) {
                Text("Remind me")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Remind me", selection: $reminderMinutes) {
                    Text("In the morning").tag(ReminderSchedule.morning)
                    Text("Before dinner").tag(ReminderSchedule.beforeDinner)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 480)
            .opacity(appeared ? 1 : 0)

            Spacer(minLength: 8)
        }
    }

    private var notificationPreview: some View {
        VStack(spacing: 8) {
            ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                previewCard(for: item, isFirst: index == 0)
                    .opacity(appeared ? (index == 0 ? 1 : 0.65) : 0)
                    .scaleEffect(index == 0 ? 1 : 0.96)
                    .offset(y: appeared ? 0 : CGFloat(24 + index * 16))
            }
        }
        .animation(.spring(duration: 0.3), value: reminderMinutes)
    }

    private func previewCard(for item: GroceryItem, isFirst: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.accentColor)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: isFirst ? String(localized: "Use today: \(item.name)") : String(localized: "Use within 2 days: \(item.name)"))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    Spacer(minLength: 4)
                    Text(verbatim: fireTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Group {
                    if let recipe = recipeName(for: item) {
                        Text(verbatim: String(localized: "Recipe idea: \(recipe)"))
                    } else {
                        Text(verbatim: String(localized: "Tap to see what you can cook."))
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private func turnOn() {
        isAsking = true
        Task {
            await NotificationManager.shared.requestPermission()
            onNext()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(Store())
}
