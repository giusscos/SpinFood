import SwiftUI
import StoreKit

// MARK: - Context

/// Why the paywall opened. Drives the headline and which feature is listed first.
enum PaywallContext: Equatable {
    case general
    case onboarding
    case milestone
    case recipeLimit
    case search
    case stats
    case shopping

    var highlighted: PaywallFeature? {
        switch self {
        case .milestone, .recipeLimit: .unlimitedRecipes
        case .search: .search
        case .stats: .stats
        case .shopping: .shopping
        case .general, .onboarding: nil
        }
    }
}

enum PaywallFeature: CaseIterable {
    case unlimitedRecipes
    case shopping
    case search
    case stats

    var icon: String {
        switch self {
        case .unlimitedRecipes: "book.fill"
        case .shopping:         "cart.fill"
        case .search:           "magnifyingglass"
        case .stats:            "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .unlimitedRecipes: .orange
        case .shopping:         .purple
        case .search:           .blue
        case .stats:            .green
        }
    }

    var title: String {
        switch self {
        case .unlimitedRecipes: "Unlimited Recipes"
        case .shopping:         "Shopping Lists"
        case .search:           "Recipe Search"
        case .stats:            "Cooking Stats"
        }
    }

    var subtitle: String {
        switch self {
        case .unlimitedRecipes: "No caps, ever"
        case .shopping:         "Built from your recipes and pantry"
        case .search:           "Find any recipe or ingredient"
        case .stats:            "What you cook, eat and waste"
        }
    }
}

// MARK: - Paywall

struct PaywallView: View {
    var context: PaywallContext = .general
    var onPurchaseComplete: (() -> Void)? = nil
    /// Replaces the default dismiss, e.g. to finish onboarding when the paywall is its last page.
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(Store.self) private var store
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"

    @State private var selectedProductID = Store.yearlyID
    @State private var trialEligibleIDs: Set<String> = []
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseError: String?
    @State private var showLifetimePlans = false
    @State private var didFinish = false

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

    private var orderedFeatures: [PaywallFeature] {
        guard let first = context.highlighted else { return PaywallFeature.allCases }
        return [first] + PaywallFeature.allCases.filter { $0 != first }
    }

    private var selectedProduct: Product? {
        store.subscriptionProducts.first { $0.id == selectedProductID } ?? store.subscriptionProducts.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                featureList
                pricingSection
                footer
            }
        }
        // Pinned so the purchase button never needs a scroll.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaSection
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(colors: [pageBackground.opacity(0), pageBackground], startPoint: .top, endPoint: .center)
                )
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .background(pageBackground.ignoresSafeArea())
        .task(id: store.subscriptionProducts.map(\.id)) { await loadTrialEligibility() }
        .onChange(of: store.hasActiveSubscription) { _, isActive in
            if isActive { finish() }
        }
        .sheet(isPresented: $showLifetimePlans) {
            PaywallLifetimeView(onPurchase: {
                Task {
                    await store.updateCustomerProductStatus()
                    finish()
                }
            })
            .presentationDetents([.medium])
        }
    }

    // MARK: - Header

    private var headerTitle: String {
        switch context {
        case .onboarding:  L("Cook more. Waste less.")
        case .milestone:   L("Your book is filling up")
        case .recipeLimit: L("Your book is full")
        case .search:      L("Find any recipe in seconds")
        case .stats:       L("See how your kitchen runs")
        case .shopping:    L("Lists that write themselves")
        case .general:     "Foo Pro"
        }
    }

    private var headerSubtitle: String {
        switch context {
        case .onboarding:
            L("Unlimited recipes, shopping lists built for you and stats on everything you cook.")
        case .milestone:
            L("Keep every recipe you love. Foo Pro has no limits.")
        case .recipeLimit:
            String(format: L("The free book holds %d recipes. Go Pro to add as many as you like."), Store.freeRecipeLimit)
        case .search:
            L("Search every recipe and ingredient in your book.")
        case .stats:
            L("What you cook, eat, refill and throw away, charted over time.")
        case .shopping:
            L("Foo builds your list from your recipes and what's left in your pantry.")
        case .general:
            L("Your whole kitchen, unlocked.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: context.highlighted?.icon ?? "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                    )
            }
            .padding(.bottom, 4)

            Text(verbatim: headerTitle)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)

            Text(verbatim: headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(orderedFeatures, id: \.self) { feature in
                OnboardingFeatureRow(
                    icon: feature.icon,
                    color: feature.color,
                    title: L(feature.title),
                    description: L(feature.subtitle)
                )
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    // MARK: - Plans

    @ViewBuilder
    private var pricingSection: some View {
        if store.subscriptionProducts.isEmpty {
            placeholderPricing
        } else {
            VStack(spacing: 10) {
                ForEach(store.subscriptionProducts) { product in
                    planCard(product)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func planName(for product: Product) -> String {
        switch product.id {
        case Store.yearlyID: L("Yearly")
        case Store.weeklyID: L("Weekly")
        case Store.familyID: L("Family")
        default: product.displayName
        }
    }

    private func planSubtitle(for product: Product) -> String {
        switch product.id {
        case Store.yearlyID:
            if let percent = savingsPercent(for: product) {
                return String(format: L("%@/week · save %d%%"), product.weeklyEquivalentText, percent)
            }
            return L("Billed yearly")
        case Store.weeklyID:
            return L("Billed weekly")
        case Store.familyID:
            return L("Up to 6 people · billed yearly")
        default:
            return product.pricePerPeriodText(bundle: currentBundle)
        }
    }

    /// Yearly vs. 52 weekly payments, rounded down so the saving is never overstated.
    private func savingsPercent(for yearly: Product) -> Int? {
        guard let weekly = store.subscriptionProducts.first(where: { $0.id == Store.weeklyID }) else { return nil }
        let fullYear = NSDecimalNumber(decimal: weekly.price * 52).doubleValue
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        guard fullYear > 0, yearlyPrice < fullYear else { return nil }
        let percent = Int(((fullYear - yearlyPrice) / fullYear * 100).rounded(.down))
        return percent > 0 ? percent : nil
    }

    private func hasEligibleTrial(_ product: Product) -> Bool {
        product.freeTrialPeriod != nil && trialEligibleIDs.contains(product.id)
    }

    private func loadTrialEligibility() async {
        var eligible: Set<String> = []
        for product in store.subscriptionProducts where product.freeTrialPeriod != nil {
            if await product.subscription?.isEligibleForIntroOffer == true {
                eligible.insert(product.id)
            }
        }
        trialEligibleIDs = eligible
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            withAnimation(.spring(duration: 0.2, bounce: 0.1)) { selectedProductID = product.id }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(verbatim: planName(for: product))
                            .font(.system(.body, design: .serif).weight(.semibold))
                        if hasEligibleTrial(product), let trial = product.freeTrialText(bundle: currentBundle) {
                            badge(String(format: L("%@ FREE"), trial).uppercased(), color: .green)
                        } else if product.id == Store.yearlyID {
                            badge(L("BEST VALUE"), color: .orange)
                        }
                    }
                    Text(verbatim: planSubtitle(for: product))
                        .font(.caption)
                        .foregroundStyle(product.id == Store.yearlyID ? Color.orange : .secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.system(.body, design: .rounded).weight(.bold))

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentColor : .secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .foregroundStyle(.primary)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground).opacity(isSelected ? 1 : 0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedProductID)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .font(.system(size: 9, weight: .bold).width(.expanded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }

    private var placeholderPricing: some View {
        VStack(spacing: 10) {
            ForEach(["Yearly", "Weekly", "Family"], id: \.self) { name in
                HStack {
                    Text(verbatim: L(name))
                    Spacer()
                    Text(verbatim: "$0.00")
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 24)
        .redacted(reason: .placeholder)
    }

    // MARK: - CTA

    private var ctaTitle: String {
        if let product = selectedProduct, hasEligibleTrial(product), let trial = product.freeTrialText(bundle: currentBundle) {
            return String(format: L("Try %@ free"), trial)
        }
        return L("Continue")
    }

    /// What the user will be charged, right under the button (Guideline 3.1.2).
    private var ctaDisclosure: String? {
        guard let product = selectedProduct else { return nil }
        let price = product.pricePerPeriodText(bundle: currentBundle)
        if hasEligibleTrial(product), let trial = product.freeTrialText(bundle: currentBundle) {
            return String(format: L("%1$@ free, then %2$@. Cancel anytime."), trial, price)
        }
        return String(format: L("%@. Cancel anytime."), price)
    }

    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await purchaseSelected() }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(verbatim: ctaTitle)
                            .font(.headline)
                            .contentTransition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isPurchasing || selectedProduct == nil)

            if let ctaDisclosure {
                Text(verbatim: ctaDisclosure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.2), value: ctaDisclosure)
            }
        }
        .padding(.horizontal, 24)
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel(Text(verbatim: L("Close")))
        .padding(.top, 12)
        .padding(.trailing, 16)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 14) {
            if let purchaseError {
                Text(verbatim: purchaseError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                showLifetimePlans = true
            } label: {
                Label(L("Prefer to pay once? Get Lifetime"), systemImage: "infinity")
                    .font(.footnote.weight(.medium))
            }
            .tint(.green)

            Button {
                Task { await restore() }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text(verbatim: L("Restore Purchases"))
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .disabled(isRestoring)

            if context == .onboarding {
                Button(action: close) {
                    Text(verbatim: L("Continue for free"))
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                        .underline()
                }
            }

            Text(verbatim: L("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period. Manage them in your Apple Account settings."))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            legalLinks
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private var legalLinks: some View {
        HStack(spacing: 8) {
            if let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(L("Terms of Use"), destination: terms)
            }
            Text(verbatim: "·")
                .foregroundStyle(.tertiary)
            if let privacy = URL(string: "https://foo-recipes.com/privacy") {
                Link(L("Privacy Policy"), destination: privacy)
            }
        }
        .font(.system(.caption, design: .serif))
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func purchaseSelected() async {
        guard let product = selectedProduct, !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        do {
            if try await store.purchase(product) != nil {
                finish()
            }
        } catch {
            purchaseError = L("The purchase couldn't be completed. Please try again.")
        }
        isPurchasing = false
    }

    private func restore() async {
        isRestoring = true
        purchaseError = nil
        try? await AppStore.sync()
        await store.updateCustomerProductStatus()
        isRestoring = false
        if store.hasActiveSubscription {
            finish()
        } else {
            purchaseError = L("No previous purchases were found for this Apple Account.")
        }
    }

    /// Purchase, restore and the entitlement observer can all land here; only the first one counts.
    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onPurchaseComplete?()
        close()
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
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
    PaywallView(context: .onboarding)
        .environment(Store())
}
