import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @Environment(\.requestReview) var requestReview

    @Query var recipes: [RecipeModel]

    @State var store = Store()
    @State var isPresentingPaywall: Bool = false

    @AppStorage("onboarding_completed") private var onboardingCompleted: Bool = false

    var hasActiveSubscription: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    var body: some View {
        if !onboardingCompleted {
            OnboardingView()
        } else if store.isLoading {
            ProgressView()
        } else {
            mainTabs
        }
    }

    private var mainTabs: some View {
        TabView {
            Tab("Summary", systemImage: "sparkles.rectangle.stack.fill") {
                NavigationStack {
                    SummaryView()
                }
            }

            Tab("Recipes", systemImage: "fork.knife") {
                NavigationStack {
                    RecipeView()
                }
            }

            Tab("Shopping", systemImage: "cart.fill") {
                ShoppingListView()
            }

            Tab("Pantry", systemImage: "carrot.fill") {
                NavigationStack {
                    FoodView()
                }
            }
        }
        .onAppear {
            if recipes.count == 2 && !hasActiveSubscription {
                isPresentingPaywall = true
            }
            if recipes.count > 2 {
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
