import SwiftUI
import SwiftData

struct BookSearchView: View {
    @Environment(AppNavigator.self) var navigator
    @Query var recipes: [RecipeModel]
    @Query var foods: [FoodModel]

    @State private var query = ""

    private var sortedRecipes: [RecipeModel] {
        recipes.sorted { $0.name < $1.name }
    }

    private var filteredRecipes: [RecipeModel] {
        query.isEmpty
            ? sortedRecipes
            : sortedRecipes.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredFoods: [FoodModel] {
        query.isEmpty
            ? []
            : foods.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filteredRecipes.isEmpty {
                    Section(query.isEmpty ? "All Recipes" : "Recipes") {
                        ForEach(filteredRecipes) { recipe in
                            Button { navigateToRecipe(recipe) } label: {
                                recipeRow(recipe)
                            }
                        }
                    }
                }

                if !filteredFoods.isEmpty {
                    Section("Pantry") {
                        ForEach(filteredFoods) { food in
                            pantryRow(food)
                        }
                    }
                }

                if !query.isEmpty && filteredRecipes.isEmpty && filteredFoods.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Recipes or ingredients…"
            )
            .navigationTitle("Search")
        }
    }

    // MARK: - Navigation

    private func navigateToRecipe(_ recipe: RecipeModel) {
        guard let index = sortedRecipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        navigator.requestedBookPage = index + 1
        navigator.selectedTab = .recipes
    }

    // MARK: - Row builders

    @ViewBuilder
    private func recipeRow(_ recipe: RecipeModel) -> some View {
        HStack(spacing: 12) {
            recipeThumb(recipe)

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)

                if recipe.duration > 0 {
                    Text(recipe.duration.formatted)
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "book.pages")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func pantryRow(_ food: FoodModel) -> some View {
        HStack(spacing: 12) {
            Text(food.emoji.isEmpty ? food.category.defaultEmoji : food.emoji)
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text("\(food.currentQuantity.formatted()) / \(food.quantity.formatted()) \(food.unit.abbreviation)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if food.isOutOfStock {
                Text("Out of stock")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if food.isLowStock {
                Text("Low")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func recipeThumb(_ recipe: RecipeModel) -> some View {
        if let data = recipe.image, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 38)
                .clipped()
                .padding(3)
                .background(.white)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 48, height: 38)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        }
    }
}
