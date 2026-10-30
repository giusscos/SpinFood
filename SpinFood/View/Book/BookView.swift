import SwiftUI
import SwiftData
import StoreKit

enum ActiveRecipeSheet: Identifiable {
    case createRecipe
    case edit(RecipeModel)
    case createFood

    var id: String {
        switch self {
        case .createRecipe:
            return "createRecipe"
        case .edit(let recipe):
            return "editRecipe-\(recipe.id)"
        case .createFood:
            return "createFood"
        }
    }
}

struct BookContainer: View {
    @Environment(\.modelContext) var modelContext
    @Environment(Store.self) var store
    @Environment(AppNavigator.self) var navigator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(BookLayout.twoPagesKey) private var prefersTwoPages = true

    @Query var recipes: [RecipeModel]

    @State private var activeRecipeSheet: ActiveRecipeSheet?
    @State private var showPaywall = false

    static let freeRecipeLimit = Store.freeRecipeLimit

    private var showsTwoPages: Bool {
        horizontalSizeClass == .regular && prefersTwoPages
    }

    private var sortedRecipes: [RecipeModel] {
        recipes.sorted {
            if $0.order != $1.order { return $0.order < $1.order }
            return $0.name < $1.name
        }
    }

    var body: some View {
        BookPageCurlView(
            recipes: sortedRecipes,
            requestedPage: navigator.requestedBookPage,
            store: store,
            navigator: navigator,
            onAdd: addRecipeTapped,
            onShowIdeas: { navigator.recipeIdeasRequest = RecipeIdeasRequest() },
            onShowIdea: { navigator.recipeIdeasRequest = RecipeIdeasRequest(recipeID: $0) },
            onEdit: { recipe in activeRecipeSheet = .edit(recipe) },
            onNavigated: { page in
                navigator.requestedBookPage = nil
                navigator.currentBookPage = page
            },
            onDeleteRecipe: handleDeleteRecipe,
            onMoveRecipes: handleMoveRecipes,
            isSpread: showsTwoPages
        )
        // The spine position is fixed when the page controller is created, so rebuild it when the
        // layout changes (folding iPhone Duo, resizing an iPad window, the setting). It reopens on the same page.
        .id(showsTwoPages)
        // The switch is on the Settings page, so stay there instead of landing on a recipe from its old spread.
        .onChange(of: prefersTwoPages) { _, _ in
            navigator.requestedBookPage = sortedRecipes.count + 1
        }
        .ignoresSafeArea()
        .fullScreenCover(item: $activeRecipeSheet) { sheet in
            switch sheet {
            case .createRecipe:
                EditRecipeView().interactiveDismissDisabled()
            case .edit(let recipe):
                EditRecipeView(recipe: recipe).interactiveDismissDisabled()
            case .createFood:
                EditFoodView()
            }
        }
        .onAppear { openRequestedRecipe() }
        .onChange(of: navigator.requestedOpenRecipeID) { _, _ in openRequestedRecipe() }
        .onChange(of: recipes.count) { _, _ in openRequestedRecipe() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .recipeLimit, onPurchaseComplete: {
                Task { await store.updateCustomerProductStatus() }
            })
            .environment(store)
        }
        .onChange(of: showPaywall) { _, isPresenting in
            if !isPresenting {
                Task { await store.updateCustomerProductStatus() }
            }
        }
    }

    private func addRecipeTapped() {
        if !store.hasActiveSubscription && recipes.countTowardFreeLimit >= Self.freeRecipeLimit {
            showPaywall = true
        } else {
            activeRecipeSheet = .createRecipe
        }
    }

    private func openRequestedRecipe() {
        guard let id = navigator.requestedOpenRecipeID,
              let index = sortedRecipes.firstIndex(where: { $0.id == id }) else { return }
        navigator.requestedOpenRecipeID = nil
        navigator.requestedBookPage = index + 1
    }

    private func handleDeleteRecipe(_ recipe: RecipeModel) {
        modelContext.delete(recipe)
        modelContext.saveConfirmedChanges()
    }

    private func handleMoveRecipes(from: IndexSet, to: Int) {
        var reordered = sortedRecipes
        reordered.move(fromOffsets: from, toOffset: to)
        for (index, recipe) in reordered.enumerated() {
            recipe.order = index
        }
    }
}

#Preview {
    BookContainer()
}
