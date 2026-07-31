import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    @State private var step: Int = 0

    private let stepCount = 4

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
                            .transition(stepTransition)
                    case 1:
                        OnboardingHowItWorksView(onNext: advance)
                            .transition(stepTransition)
                    case 2:
                        OnboardingPermissionsView(onNext: advance)
                            .transition(stepTransition)
                    case 3:
                        OnboardingUpsellView(onNext: completeOnboarding, onComplete: completeOnboarding)
                            .transition(stepTransition)
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private var stepTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.96))
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { i in
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
    @State private var dishesAppeared = false
    @State private var row1Appeared = false
    @State private var row2Appeared = false
    @State private var row3Appeared = false
    @State private var buttonAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                OnboardingDishCluster(appeared: dishesAppeared)

                VStack(spacing: 12) {
                    Text("Welcome to Foo")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Track your pantry, plan your meals,\nand reduce food waste every day.")
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
                    icon: "leaf.fill",
                    color: .green,
                    title: "Reduce food waste",
                    description: "Know what you have before buying more"
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "cart.fill",
                    color: .blue,
                    title: "Shop smarter",
                    description: "Generate shopping lists from your recipes"
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    color: .orange,
                    title: "Track habits",
                    description: "See what you consume and when"
                )
                .opacity(row3Appeared ? 1 : 0)
                .blur(radius: row3Appeared ? 0 : 8)
                .offset(y: row3Appeared ? 0 : 18)
                .scaleEffect(row3Appeared ? 1 : 0.94, anchor: .leading)
            }
            .padding(.horizontal, 24)

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

// MARK: - Upsell Step

struct OnboardingUpsellView: View {
    let onNext: () -> Void
    let onComplete: () -> Void

    @Environment(Store.self) private var store
    @AppStorage("onboarding_upsell_seen") private var onboardingUpsellSeen: Bool = false
    @State private var appeared = false
    @State private var row1Appeared = false
    @State private var row2Appeared = false
    @State private var row3Appeared = false
    @State private var row4Appeared = false
    @State private var buttonAppeared = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.14))
                        .frame(width: 90, height: 90)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                        )
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .blur(radius: appeared ? 0 : 12)

                Text("Get the most out of Foo")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Unlock everything — so nothing goes to waste.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 10)
            .offset(y: appeared ? 0 : 16)

            Spacer(minLength: 20)

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "book.fill",
                    color: .orange,
                    title: "Unlimited Recipes",
                    description: "Add as many recipes as your kitchen needs — no caps, ever"
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "magnifyingglass",
                    color: .blue,
                    title: "Recipe Search",
                    description: "Find any recipe instantly across your whole collection"
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    color: .green,
                    title: "Cooking Stats",
                    description: "Every meal charted — what you cook, when, and how often"
                )
                .opacity(row3Appeared ? 1 : 0)
                .blur(radius: row3Appeared ? 0 : 8)
                .offset(y: row3Appeared ? 0 : 18)
                .scaleEffect(row3Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "cart.fill",
                    color: .purple,
                    title: "Shopping Lists",
                    description: "Auto-generated from your recipes so you never miss an ingredient"
                )
                .opacity(row4Appeared ? 1 : 0)
                .blur(radius: row4Appeared ? 0 : 8)
                .offset(y: row4Appeared ? 0 : 18)
                .scaleEffect(row4Appeared ? 1 : 0.94, anchor: .leading)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            VStack(spacing: 12) {
                Button {
                    showPaywall = true
                } label: {
                    Text("See Plans")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button(action: onNext) {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(buttonAppeared ? 1 : 0)
            .blur(radius: buttonAppeared ? 0 : 6)
            .scaleEffect(buttonAppeared ? 1 : 0.88)
        }
        .onAppear {
            onboardingUpsellSeen = true
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) { appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.32)) { row1Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.45)) { row2Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.58)) { row3Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.71)) { row4Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.88)) { buttonAppeared = true }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(onPurchaseComplete: {
                showPaywall = false
                onComplete()
            })
            .environment(store)
        }
    }
}

// MARK: - How It Works Step

struct OnboardingHowItWorksView: View {
    let onNext: () -> Void
    @State private var appeared = false
    @State private var row1Appeared = false
    @State private var row2Appeared = false
    @State private var row3Appeared = false
    @State private var row4Appeared = false
    @State private var buttonAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .blur(radius: appeared ? 0 : 12)

                Text("How Foo works")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("A quick tour of the kitchen loop — from pantry to plate and back again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 10)
            .offset(y: appeared ? 0 : 16)

            Spacer(minLength: 20)

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "carrot.fill",
                    color: .green,
                    title: "Add ingredients",
                    description: "Stock your pantry, then attach those foods to a recipe with the amounts you need"
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "list.number",
                    color: .blue,
                    title: "Write the steps",
                    description: "Break the recipe into clear cooking steps you can follow page by page"
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Cook",
                    description: "Start cooking from the book — timers keep time, and ingredients leave your pantry when you're done"
                )
                .opacity(row3Appeared ? 1 : 0)
                .blur(radius: row3Appeared ? 0 : 8)
                .offset(y: row3Appeared ? 0 : 18)
                .scaleEffect(row3Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "arrow.trianglehead.counterclockwise",
                    color: .purple,
                    title: "Refill",
                    description: "When stock runs low, shop from the list and refill items to top your pantry back up"
                )
                .opacity(row4Appeared ? 1 : 0)
                .blur(radius: row4Appeared ? 0 : 8)
                .offset(y: row4Appeared ? 0 : 18)
                .scaleEffect(row4Appeared ? 1 : 0.94, anchor: .leading)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 20)

            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(buttonAppeared ? 1 : 0)
            .blur(radius: buttonAppeared ? 0 : 6)
            .scaleEffect(buttonAppeared ? 1 : 0.88)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) { appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.32)) { row1Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.45)) { row2Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.58)) { row3Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.71)) { row4Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.88)) { buttonAppeared = true }
        }
    }
}

// MARK: - Permissions Step

struct OnboardingPermissionsView: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var row1Appeared = false
    @State private var row2Appeared = false
    @State private var buttonAppeared = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.orange)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .blur(radius: appeared ? 0 : 12)

                Text("Stay on top of your kitchen")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Foo needs a couple of permissions so timers and pantry alerts work when you're away from the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 10)
            .offset(y: appeared ? 0 : 16)

            Spacer()

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "bell.fill",
                    color: .blue,
                    title: "Notifications",
                    description: "Expiry reminders and low-stock alerts for your pantry"
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "alarm.fill",
                    color: .orange,
                    title: "Alarms",
                    description: "Cooking timers that ring even if your phone is on silent"
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task { await requestPermissionsAndContinue() }
            } label: {
                HStack(spacing: 8) {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isRequesting ? "Please wait…" : "Continue")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isRequesting)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(buttonAppeared ? 1 : 0)
            .blur(radius: buttonAppeared ? 0 : 6)
            .scaleEffect(buttonAppeared ? 1 : 0.88)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) { appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.32)) { row1Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.48)) { row2Appeared = true }
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.65)) { buttonAppeared = true }
        }
    }

    private func requestPermissionsAndContinue() async {
        guard !isRequesting else { return }
        isRequesting = true
        _ = await NotificationManager.shared.requestPermission()
        _ = await CookTimerAlarmScheduler.requestAuthorization()
        isRequesting = false
        onNext()
    }
}
