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
    @State private var navigator = AppNavigator()

    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false
    @AppStorage("onboarding_upsell_seen") private var onboardingUpsellSeen: Bool = false

    var body: some View {
        if !onboardingCompleted {
            OnboardingView()
                .environment(store)
        } else if store.isLoading {
            ProgressView()
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
            if recipes.count >= 3 && !store.hasActiveSubscription && !onboardingUpsellSeen {
                isPresentingPaywall = true
            }
            if recipes.count >= 5 && store.hasActiveSubscription {
                requestReview()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationManager.shared.scheduleAll(foods: foods)
                WidgetSnapshotStore.refresh(foods: foods, meals: mealPlan, recipes: recipes)
                Task { await store.updateCustomerProductStatus() }
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
        }
        .fullScreenCover(isPresented: $isPresentingPaywall) {
            PaywallView(onPurchaseComplete: {
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
}

#Preview {
    ContentView()
}
