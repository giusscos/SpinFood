import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State var store = Store()
    @State private var showLifetimePlans = false

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
                coverContent
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .containerBackground(pageBackground, for: .subscriptionStoreFullHeight)
            .subscriptionStoreControlBackground(pageBackground)
            .onInAppPurchaseCompletion { _, result in
                if case .success = result {
                    dismiss()
                }
            }
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView(onPurchase: { dismiss() })
                    .presentationDetents([.medium])
            }
        }
        .background(pageBackground.ignoresSafeArea())
    }

    // MARK: - Book Cover

    private var coverContent: some View {
        VStack(spacing: 30) {
            // Title block
            VStack(spacing: 8) {
                Text("FOO")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .tracking(5)

                Text("Premium Edition")
                    .font(.system(size: 11, weight: .regular, design: .serif))
                    .foregroundStyle(.secondary)
                    .tracking(3)
                    .textCase(.uppercase)
            }
            .padding(.top)

            Image(systemName: "fork.knife")
                .font(.system(size: 20))
                .foregroundStyle(.orange.opacity(0.85))

            // Table of contents
            VStack(spacing: 24) {
                tocEntry(roman: "I",   title: "Unlimited Recipes",  note: "No caps, ever")
                tocDivider
                tocEntry(roman: "II",  title: "Recipe Search",      note: "Find anything instantly")
                tocDivider
                tocEntry(roman: "III", title: "Cooking Stats",      note: "Every meal charted")
                tocDivider
                tocEntry(roman: "IV",  title: "Shopping Lists",     note: "Auto-generated")
            }

            // Lifetime purchase link
            Button {
                showLifetimePlans = true
            } label: {
                Label("One-time purchase available", systemImage: "infinity")
                    .font(.footnote)
            }
            .tint(.green)

            legalLinks
                .padding(.vertical, 12)
        }
        .padding(.horizontal)
        .background(pageBackground.ignoresSafeArea())
    }

    // MARK: - Table of Contents Entry

    private func tocEntry(roman: String, title: String, note: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(roman)
                .font(.system(size: 11, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(.body, design: .serif))

                Text(note)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(". . . . . . .")
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .layoutPriority(-1)
        }
        .padding(.vertical, 11)
    }

    // MARK: - Ornaments

    private var tocDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.1))
            .frame(height: 0.5)
    }

    // MARK: - Legal

    private var legalLinks: some View {
        HStack(spacing: 8) {
            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            
            Text("·")
                .foregroundStyle(.tertiary)
            
            Link("Privacy Policy", destination: URL(string: "https://foo-recipe.com/privacy")!)
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
}
