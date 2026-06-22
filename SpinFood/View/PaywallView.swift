import SwiftUI
import StoreKit

struct PaywallView: View {
    @State var store = Store()
    @State private var showLifetimePlans = false

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: store.groupId) {
                paywallContent
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView()
                    .presentationDetents([.medium])
            }
        }
    }

    private var paywallContent: some View {
        VStack(spacing: 24) {
            heroSection

            featuresGrid

            lifetimeButton

            legalLinks
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.indigo.opacity(0.15), .purple.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 96, height: 96)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            }

            VStack(spacing: 6) {
                Text("Cook Without Limits")
                    .font(.title2.bold())

                Text("Unlock the full SpinFood experience —\nunlimited recipes, smart tools, and rich stats.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Feature Grid

    private var featuresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProFeatureCard(
                icon: "infinity",
                color: .indigo,
                title: "Unlimited Recipes",
                description: "No caps, ever"
            )
            ProFeatureCard(
                icon: "chart.bar.xaxis.ascending",
                color: .orange,
                title: "Cooking Stats",
                description: "Track every meal"
            )
            ProFeatureCard(
                icon: "cart.fill",
                color: .green,
                title: "Smart Shopping",
                description: "Instant refill lists"
            )
            ProFeatureCard(
                icon: "leaf.fill",
                color: .teal,
                title: "Less Waste",
                description: "Know what you use"
            )
        }
    }

    // MARK: - Lifetime Button

    private var lifetimeButton: some View {
        Button {
            showLifetimePlans = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "infinity.circle.fill")
                Text("One-time purchase available")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .tint(.orange)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
    }

    // MARK: - Legal

    private var legalLinks: some View {
        HStack(spacing: 8) {
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .foregroundColor(.secondary)
            Text("·")
                .foregroundStyle(.tertiary)
            Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - Feature Card

struct ProFeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.13))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Legacy row (kept for compatibility)

struct ProFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    PaywallView()
}
