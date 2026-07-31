import SwiftUI
import StoreKit

struct PaywallView: View {
    var onPurchaseComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(Store.self) private var store
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"
    @State private var showLifetimePlans = false

    private var currentBundle: Bundle {
        Bundle.main.path(forResource: selectedLanguage, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
    }

    private func L(_ key: String) -> String {
        currentBundle.localizedString(forKey: key, value: key, table: nil)
    }

    private var pageBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
        })
    }

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: store.groupId) {
                VStack(spacing: 30) {
                    // Title block
                    VStack(spacing: 8) {
                        Text("Foo")
                            .font(.system(size: 34, weight: .bold, design: .serif))

                        Text("Premium Edition")
                            .font(.system(size: 11, weight: .regular, design: .serif))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }

                    VStack(spacing: 14) {
                        OnboardingFeatureRow(
                            icon: "book.fill",
                            color: .orange,
                            title: L("Unlimited Recipes"),
                            description: L("No caps, ever")
                        )
                        OnboardingFeatureRow(
                            icon: "magnifyingglass",
                            color: .blue,
                            title: L("Recipe Search"),
                            description: L("Find anything instantly")
                        )
                        OnboardingFeatureRow(
                            icon: "chart.bar.fill",
                            color: .green,
                            title: L("Cooking Stats"),
                            description: L("Every meal charted")
                        )
                        OnboardingFeatureRow(
                            icon: "cart.fill",
                            color: .purple,
                            title: L("Shopping Lists"),
                            description: L("Auto-generated")
                        )
                    }

                    // Lifetime purchase link
                    Button {
                        showLifetimePlans = true
                    } label: {
                        Label(L("One-time purchase"), systemImage: "infinity")
                            .font(.footnote)
                    }
                    .tint(.green)

                    legalLinks
                        .padding(.vertical, 12)
                }
                .padding(.horizontal)
                .background(pageBackground.ignoresSafeArea())

            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .containerBackground(pageBackground, for: .subscriptionStoreFullHeight)
            .subscriptionStoreControlBackground(pageBackground)
            .onInAppPurchaseCompletion { _, result in
                if case .success(let purchaseResult) = result,
                   case .success(let verification) = purchaseResult {
                    Task {
                        await store.handlePurchaseSuccess(verification)
                        onPurchaseComplete?()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView(onPurchase: {
                    Task {
                        await store.updateCustomerProductStatus()
                        onPurchaseComplete?()
                        dismiss()
                    }
                })
                .presentationDetents([.medium])
            }
            .background(pageBackground.ignoresSafeArea())
        }
        .background(pageBackground.ignoresSafeArea())
    }

    // MARK: - Legal

    private var legalLinks: some View {
        HStack(spacing: 8) {
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            
            Text("·")
                .foregroundStyle(.tertiary)
            
            Link("Privacy Policy", destination: URL(string: "https://foo-recipes.com/privacy")!)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
        }
        .font(.system(.caption, design: .serif))
    }
}

// MARK: - Feature Card (used in other contexts)

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
        .environment(Store())
}
