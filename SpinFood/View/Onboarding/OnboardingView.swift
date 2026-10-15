import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false
    @Environment(Store.self) private var store

    @State private var step: Int = 0

    // Kept short so people reach their recipe book quickly. Notifications are requested
    // when the first pantry item is added, and alarms when the first cook timer starts.
    private static let paywallStep = 2

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
                        OnboardingHowItWorksView(onNext: advance)
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
                    icon: "barcode.viewfinder",
                    color: .blue,
                    title: String(localized: "Scan to stock up"),
                    description: String(localized: "Add groceries in seconds with the barcode scanner")
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

                Text("From pantry to plate")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Four steps, and your kitchen runs itself.")
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
                    title: String(localized: "Add ingredients"),
                    description: String(localized: "Stock your pantry and link foods to your recipes")
                )
                .opacity(row1Appeared ? 1 : 0)
                .blur(radius: row1Appeared ? 0 : 8)
                .offset(y: row1Appeared ? 0 : 18)
                .scaleEffect(row1Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "list.number",
                    color: .blue,
                    title: String(localized: "Write the steps"),
                    description: String(localized: "Follow clear steps, page by page")
                )
                .opacity(row2Appeared ? 1 : 0)
                .blur(radius: row2Appeared ? 0 : 8)
                .offset(y: row2Appeared ? 0 : 18)
                .scaleEffect(row2Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: String(localized: "Cook"),
                    description: String(localized: "Timers keep time, and used ingredients leave your pantry")
                )
                .opacity(row3Appeared ? 1 : 0)
                .blur(radius: row3Appeared ? 0 : 8)
                .offset(y: row3Appeared ? 0 : 18)
                .scaleEffect(row3Appeared ? 1 : 0.94, anchor: .leading)

                OnboardingFeatureRow(
                    icon: "arrow.trianglehead.counterclockwise",
                    color: .purple,
                    title: String(localized: "Refill"),
                    description: String(localized: "Shop from the list and top your pantry back up")
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

#Preview {
    OnboardingView()
        .environment(Store())
}
