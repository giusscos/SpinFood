import SwiftUI
import SwiftData
import StoreKit

enum AppTab: Hashable {
    case recipes, inventory, shopping, summary, search
}

struct ContentView: View {
    @Environment(\.requestReview) var requestReview

    @Query var recipes: [RecipeModel]

    @State var store = Store()
    @State var isPresentingPaywall: Bool = false
    @State private var navigator = AppNavigator()

    var body: some View {
        if store.isLoading {
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
            if recipes.count >= 3 && !store.hasActiveSubscription {
                isPresentingPaywall = true
            }
            if recipes.count >= 5 && store.hasActiveSubscription {
                requestReview()
            }
        }
        .fullScreenCover(isPresented: $isPresentingPaywall) {
            PaywallView()
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
