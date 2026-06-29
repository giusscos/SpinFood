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

    @Query var recipes: [RecipeModel]

    @State private var activeRecipeSheet: ActiveRecipeSheet?
    @State private var showPaywall = false

    static let freeRecipeLimit = 3

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
            onAdd: addRecipeTapped,
            onEdit: { recipe in activeRecipeSheet = .edit(recipe) },
            onNavigated: { page in
                navigator.requestedBookPage = nil
                navigator.currentBookPage = page
            },
            onDeleteRecipe: handleDeleteRecipe,
            onMoveRecipes: handleMoveRecipes
        )
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
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func addRecipeTapped() {
        if !store.hasActiveSubscription && recipes.count >= Self.freeRecipeLimit {
            showPaywall = true
        } else {
            activeRecipeSheet = .createRecipe
        }
    }

    private func handleDeleteRecipe(_ recipe: RecipeModel) {
        modelContext.delete(recipe)
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
