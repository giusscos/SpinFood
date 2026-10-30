import SwiftUI
import SwiftData
import StoreKit

enum AppTab: Hashable {
    case recipes, inventory, shopping, summary, search
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]
    @Query var mealPlan: [MealPlanEntry]
    @Query(filter: #Predicate<FoodConsumptionModel> { $0.rescued }) private var savedRecords: [FoodConsumptionModel]
    @Query private var wasteRecords: [FoodWasteModel]

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

    private var tabs: some View {
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
    }

    private var tabsWithFeedback: some View {
        tabs
            .overlay(alignment: .bottom) {
                if let names = navigator.savedFoodNames {
                    savedFoodBanner(names: names)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: navigator.savedFoodNames)
            .sensoryFeedback(.success, trigger: navigator.savedFoodNames) { _, new in new != nil }
            .task(id: navigator.savedFoodNames) {
                guard navigator.savedFoodNames != nil else { return }
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                navigator.savedFoodNames = nil
            }
            .sheet(item: Binding(
                get: { navigator.recipeIdeasRequest },
                set: { navigator.recipeIdeasRequest = $0 }
            )) { request in
                RecipeIdeasView(initialRecipeID: request.recipeID)
                    .environment(navigator)
            }
    }

    private var coreTabView: some View {
        tabsWithFeedback
        .onAppear {
            rescheduleReminders()
            NotificationManager.shared.clearBadge()
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            consumePendingWidgetCook()
            openPendingReminder()
            if !store.isLoading { handleLaunchPrompts() }
        }
        .onChange(of: NotificationManager.shared.pendingRoute) { _, _ in
            openPendingReminder()
        }
        .onChange(of: NotificationManager.shared.rescheduleRequests) { _, _ in
            rescheduleReminders()
        }
        .onChange(of: store.isLoading) { _, isLoading in
            if !isLoading { handleLaunchPrompts() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                rescheduleReminders()
                NotificationManager.shared.clearBadge()
                WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
                consumePendingWidgetCook()
                Task { await store.updateCustomerProductStatus() }
            } else if phase == .background {
                // Everything changed while the app was open is reflected in what it says next.
                rescheduleReminders()
                WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
            }
        }
        .onChange(of: foods.count) { _, _ in
            WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
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

    private func rescheduleReminders() {
        NotificationManager.shared.reschedule(
            foods: foods,
            recipes: recipes,
            savedRecords: savedRecords,
            wasteRecords: wasteRecords
        )
    }

    private func openPendingReminder() {
        guard let route = NotificationManager.shared.pendingRoute else { return }
        NotificationManager.shared.pendingRoute = nil
        switch route {
        case .recipeIdeas:
            navigator.selectedTab = .recipes
            navigator.recipeIdeasRequest = RecipeIdeasRequest()
        case .recipeIdea(let id):
            navigator.selectedTab = .recipes
            navigator.recipeIdeasRequest = RecipeIdeasRequest(recipeID: id)
        case .bookRecipe(let id):
            navigator.selectedTab = .recipes
            navigator.requestedOpenRecipeID = id
        case .inventory:
            navigator.selectedTab = .inventory
        case .quickAdd:
            navigator.selectedTab = .inventory
            navigator.requestedQuickAdd = true
        }
    }

    private func savedFoodBanner(names: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 1) {
                Text("Saved from the bin: \(names)")
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .lineLimit(2)
                Text("Foods saved so far: \(savedRecords.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .rect(cornerRadius: 18))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 92)
    }

    private func handleLaunchPrompts() {
        // Once per install, after the free book fills up.
        if recipes.countTowardFreeLimit >= Store.freeRecipeLimit && !store.hasActiveSubscription && !milestonePaywallShown {
            milestonePaywallShown = true
            paywallContext = .milestone
            isPresentingPaywall = true
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
