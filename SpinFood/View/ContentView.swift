import SwiftUI
import SwiftData
import StoreKit

enum AppTab: Hashable {
    case recipes, inventory, shopping, summary, search
}

struct ContentView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.scenePhase) private var scenePhase

    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]
    @Query var mealPlan: [MealPlanEntry]

    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"

    @State var store = Store()
    @State var isPresentingPaywall: Bool = false
    @State private var paywallContext: PaywallContext = .general
    @State private var launchWaitElapsed = false
    @State private var navigator = AppNavigator()

    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false
    @AppStorage("milestone_paywall_shown") private var milestonePaywallShown: Bool = false

    var body: some View {
        if !onboardingCompleted {
            OnboardingView()
                .environment(store)
        } else if store.isLoading && !launchWaitElapsed {
            // StoreKit can take seconds without a network; don't hold the whole app for it.
            // Entitlement-dependent prompts wait for `store.isLoading` in `handleLaunchPrompts`.
            ProgressView()
                .task {
                    try? await Task.sleep(for: .milliseconds(400))
                    launchWaitElapsed = true
                }
        } else {
            mainTabView
        }
    }

    @ViewBuilder
    private var mainTabView: some View {
        if #available(iOS 26.1, *) {
            let showRefill = navigator.checkedShoppingItemsCount > 0 && navigator.selectedTab == .shopping
            let showUpgrade = !store.hasActiveSubscription && (navigator.selectedTab == .shopping || navigator.selectedTab == .summary)
            coreTabView
                .tabViewBottomAccessory(isEnabled: showRefill || showUpgrade) {
                    if showRefill {
                        Button {
                            navigator.triggerShoppingRefill = true
                        } label: {
                            Label(
                                "Refill \(navigator.checkedShoppingItemsCount) Selected",
                                systemImage: "bag.fill.badge.plus"
                            )
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    } else {
                        Button {
                            paywallContext = navigator.selectedTab == .shopping ? .shopping : .stats
                            isPresentingPaywall = true
                        } label: {
                            Text("Upgrade to Pro")
                                .font(.system(.body, design: .serif).weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                }
        } else {
            coreTabView
        }
    }

    private var coreTabView: some View {
        TabView(selection: Binding(
            get: { navigator.selectedTab },
            set: { navigator.selectedTab = $0 }
        )) {
            Tab("Summary", systemImage: "chart.bar.xaxis.ascending", value: AppTab.summary) {
                NavigationStack {
                    SummaryView()
                }
            }
            
            Tab("Recipes", systemImage: "book.fill", value: AppTab.recipes) {
                BookContainer()
            }

            Tab("Inventory", systemImage: "cabinet.fill", value: AppTab.inventory) {
                NavigationStack {
                    FoodView()
                }
            }

            Tab("Shopping", systemImage: "cart.fill", value: AppTab.shopping) {
                ShoppingListView()
            }

            Tab(value: AppTab.search, role: .search) {
                BookSearchView()
            }
        }
        .environment(store)
        .environment(navigator)
        .onAppear {
            NotificationManager.shared.scheduleAll(foods: foods)
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            consumePendingWidgetCook()
            if !store.isLoading { handleLaunchPrompts() }
        }
        .onChange(of: store.isLoading) { _, isLoading in
            if !isLoading { handleLaunchPrompts() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationManager.shared.scheduleAll(foods: foods)
                WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
                consumePendingWidgetCook()
                Task { await store.updateCustomerProductStatus() }
            } else if phase == .background {
                WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            }
        }
        .onChange(of: foods.count) { oldCount, newCount in
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            // Ask for expiry and low-stock alerts once there's something to alert about.
            if oldCount == 0 && newCount > 0 {
                Task {
                    await NotificationManager.shared.requestPermission()
                    NotificationManager.shared.scheduleAll(foods: foods)
                }
            }
        }
        .onChange(of: mealPlan.count) { _, _ in
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
        }
        .onChange(of: recipes.count) { _, _ in
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            consumePendingWidgetCook()
        }
        .fullScreenCover(isPresented: $isPresentingPaywall) {
            PaywallView(context: paywallContext, onPurchaseComplete: {
                Task { await store.updateCustomerProductStatus() }
            })
            .environment(store)
            .environment(\.locale, Locale(identifier: selectedLanguage))
        }
        .onChange(of: isPresentingPaywall) { _, isPresenting in
            if !isPresenting {
                Task { await store.updateCustomerProductStatus() }
            }
        }
    }

    private func handleLaunchPrompts() {
        // Once per install, after the free book fills up.
        if recipes.count >= Store.freeRecipeLimit && !store.hasActiveSubscription && !milestonePaywallShown {
            milestonePaywallShown = true
            paywallContext = .milestone
            isPresentingPaywall = true
        }
        if recipes.count >= 5 && store.hasActiveSubscription {
            requestReview()
        }
    }

    private func consumePendingWidgetCook() {
        guard let idString = AppGroupContainer.sharedDefaults.string(forKey: AppGroupContainer.pendingCookRecipeIDKey),
              let id = UUID(uuidString: idString) else { return }

        let sorted = recipes.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.name < $1.name
        }
        guard let index = sorted.firstIndex(where: { $0.id == id }) else { return }

        AppGroupContainer.sharedDefaults.removeObject(forKey: AppGroupContainer.pendingCookRecipeIDKey)
        navigator.selectedTab = .recipes
        navigator.requestedCookRecipeID = id
        navigator.requestedBookPage = index + 1
    }
}

#Preview {
    ContentView()
}
