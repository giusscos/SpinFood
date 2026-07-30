import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    @State private var step: Int = 0

    private let stepCount = 3

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
                        OnboardingPermissionsView(onNext: completeOnboarding)
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
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
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
                OnboardingFeatureRow(
                    icon: "leaf.fill",
                    color: .green,
                    title: "Reduce food waste",
                    description: "Know what you have before buying more"
                )
                OnboardingFeatureRow(
                    icon: "cart.fill",
                    color: .blue,
                    title: "Shop smarter",
                    description: "Generate shopping lists from your recipes"
                )
                OnboardingFeatureRow(
                    icon: "chart.bar.fill",
                    color: .orange,
                    title: "Track habits",
                    description: "See what you consume and when"
                )
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

// MARK: - How It Works Step

struct OnboardingHowItWorksView: View {
    let onNext: () -> Void
    @State private var appeared = false

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

                Text("How SpinFood works")
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
            .offset(y: appeared ? 0 : 16)

            Spacer(minLength: 20)

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "carrot.fill",
                    color: .green,
                    title: "Add ingredients",
                    description: "Stock your pantry, then attach those foods to a recipe with the amounts you need"
                )
                OnboardingFeatureRow(
                    icon: "list.number",
                    color: .blue,
                    title: "Write the steps",
                    description: "Break the recipe into clear cooking steps you can follow page by page"
                )
                OnboardingFeatureRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Cook",
                    description: "Start cooking from the book — timers keep time, and ingredients leave your pantry when you’re done"
                )
                OnboardingFeatureRow(
                    icon: "arrow.trianglehead.counterclockwise",
                    color: .purple,
                    title: "Refill",
                    description: "When stock runs low, shop from the list and refill items to top your pantry back up"
                )
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)

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
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Permissions Step

struct OnboardingPermissionsView: View {
    let onNext: () -> Void

    @State private var appeared = false
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

                Text("Stay on top of your kitchen")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("SpinFood needs a couple of permissions so timers and pantry alerts work when you’re away from the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            Spacer()

            VStack(spacing: 14) {
                OnboardingFeatureRow(
                    icon: "bell.fill",
                    color: .blue,
                    title: "Notifications",
                    description: "Expiry reminders and low-stock alerts for your pantry"
                )
                OnboardingFeatureRow(
                    icon: "alarm.fill",
                    color: .orange,
                    title: "Alarms",
                    description: "Cooking timers that ring even if your phone is on silent"
                )
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)

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
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) {
                appeared = true
            }
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
