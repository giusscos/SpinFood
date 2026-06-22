import SwiftUI
import SwiftData
import StoreKit

enum AppTab: Hashable {
    case recipes, inventory, search
}

struct ContentView: View {
    @Environment(\.requestReview) var requestReview

    @Query var recipes: [RecipeModel]

    @State var store = Store()
    @State var isPresentingPaywall: Bool = false
    @State private var navigator = AppNavigator()

    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    var body: some View {
        if !onboardingCompleted {
            OnboardingView()
        } else if store.isLoading {
            ProgressView()
        } else {
            mainTabView
        }
    }

    private var mainTabView: some View {
        TabView(selection: Binding(
            get: { navigator.selectedTab },
            set: { navigator.selectedTab = $0 }
        )) {
            Tab("Recipes", systemImage: "book.fill", value: AppTab.recipes) {
                BookContainer()
            }

            Tab("Inventory", systemImage: "cabinet.fill", value: AppTab.inventory) {
                NavigationStack {
                    FoodView()
                }
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
    }
}

#Preview {
    ContentView()
}
