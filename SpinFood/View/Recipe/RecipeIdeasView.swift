import SwiftUI
import SwiftData

/// Foo's own recipes, ranked by what's in the kitchen: whatever saves expiring food comes first.
struct RecipeIdeasView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigator.self) private var navigator

    @Query private var foods: [FoodModel]
    @Query private var recipes: [RecipeModel]

    @State private var showQuickAdd = false
    @State private var path: [String]

    init(initialRecipeID: String? = nil) {
        _path = State(initialValue: initialRecipeID.map { [$0] } ?? [])
    }

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    private var hasStock: Bool {
        foods.contains { !$0.isOutOfStock }
    }

    private var ideas: [RecipeIdea] {
        StarterRecipe.all.map { RecipeIdea(recipe: $0, foods: foods) }
    }

    private var useItUp: [RecipeIdea] {
        ideas
            .filter { !$0.expiring.isEmpty }
            .sorted { $0.expiring.count > $1.expiring.count }
    }

    private var readyToCook: [RecipeIdea] {
        ideas.filter { $0.expiring.isEmpty && $0.missing.isEmpty }
    }

    private var almostThere: [RecipeIdea] {
        ideas
            .filter { $0.expiring.isEmpty && (1...2).contains($0.missing.count) }
            .sorted { $0.missing.count < $1.missing.count }
    }

    private var moreIdeas: [RecipeIdea] {
        ideas
            .filter { $0.expiring.isEmpty && $0.missing.count > 2 }
            .sorted { $0.missing.count < $1.missing.count }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if !hasStock {
                        stockPrompt
                    }
                    ideaSection("Use it up", systemImage: "clock.badge.exclamationmark", tint: .orange, ideas: useItUp)
                    ideaSection("Ready to cook", systemImage: "checkmark.circle.fill", tint: .green, ideas: readyToCook)
                    ideaSection("Almost there", systemImage: "cart", tint: .secondary, ideas: almostThere)
                    ideaSection("More ideas", systemImage: "lightbulb", tint: .secondary, ideas: moreIdeas)
                }
                .padding()
            }
            .background(paperBackground.ignoresSafeArea())
            .navigationTitle("Recipe Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .navigationDestination(for: String.self) { recipeID in
                if let recipe = StarterRecipe.all.first(where: { $0.id == recipeID }) {
                    RecipeIdeaDetailView(
                        idea: RecipeIdea(recipe: recipe, foods: foods),
                        bookRecipe: bookRecipe(for: recipe),
                        onAdd: { add(recipe) },
                        onOpen: { open(recipe) }
                    )
                }
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddFoodView()
            }
        }
    }

    private var stockPrompt: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tell Foo what you have")
                .font(.system(.headline, design: .serif))
            Text("Add your food to see what you can cook right now, and what to use first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showQuickAdd = true
            } label: {
                Label("Add Food", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func ideaSection(
        _ title: LocalizedStringKey,
        systemImage: String,
        tint: Color,
        ideas: [RecipeIdea]
    ) -> some View {
        if !ideas.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)

                ForEach(ideas) { idea in
                    NavigationLink(value: idea.id) {
                        RecipeIdeaRow(
                            idea: idea,
                            isInBook: bookRecipe(for: idea.recipe) != nil,
                            onAdd: { add(idea.recipe) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bookRecipe(for recipe: StarterRecipe) -> RecipeModel? {
        recipes.first { $0.catalogID == recipe.id }
    }

    private func add(_ recipe: StarterRecipe) {
        guard bookRecipe(for: recipe) == nil else { return }
        withAnimation {
            recipe.addToBook(foods: foods, in: modelContext)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func open(_ recipe: StarterRecipe) {
        guard let bookRecipe = bookRecipe(for: recipe) else { return }
        navigator.selectedTab = .recipes
        navigator.requestedOpenRecipeID = bookRecipe.id
        dismiss()
    }
}

// MARK: - Row

private struct RecipeIdeaRow: View {
    let idea: RecipeIdea
    let isInBook: Bool
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(idea.recipe.emoji)
                .font(.system(size: 30))
                .frame(width: 56, height: 56)
                .background(Color.accentColor.opacity(0.12), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(idea.recipe.localizedName)
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(idea.recipe.minutes) min · \(idea.recipe.servings) servings")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                statusLine
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            if isInBook {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("In your book")
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add to my book")
            }
        }
        .padding(10)
        .background(.secondary.opacity(0.07), in: .rect(cornerRadius: 16))
        .contentShape(.rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var statusLine: some View {
        if !idea.expiring.isEmpty {
            let names = idea.expiring.map(\.grocery.name).formatted(.list(type: .and))
            Text("Uses \(names) before it expires")
                .foregroundStyle(.orange)
        } else if idea.missing.isEmpty {
            Text("You have everything")
                .foregroundStyle(.green)
        } else {
            Text("\(idea.missing.count) missing: \(idea.missing.prefix(3).map(\.grocery.name).formatted(.list(type: .and)))")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Detail

private struct RecipeIdeaDetailView: View {
    let idea: RecipeIdea
    let bookRecipe: RecipeModel?
    var onAdd: () -> Void
    var onOpen: () -> Void

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 10) {
                    Text(idea.recipe.emoji)
                        .font(.system(size: 64))
                    Text(idea.recipe.localizedName)
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(idea.recipe.localizedSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("\(idea.recipe.minutes) min · \(idea.recipe.servings) servings")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.system(.headline, design: .serif))

                    ForEach(idea.items) { item in
                        HStack(spacing: 10) {
                            Text(item.grocery.emoji)
                            Text(item.grocery.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.quantity.formatted()) \(item.grocery.unit.abbreviation)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: item.isInStock ? "checkmark.circle.fill" : "cart")
                                .foregroundStyle(item.isInStock ? .green : .secondary)
                                .accessibilityLabel(item.isInStock ? "In stock" : "Out of stock")
                        }
                    }

                    if !idea.missing.isEmpty && bookRecipe == nil {
                        Text("Adding this recipe lists what's missing in your inventory as out of stock.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Steps")
                        .font(.system(.headline, design: .serif))

                    ForEach(Array(idea.recipe.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(.subheadline, design: .serif).weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 18, alignment: .leading)
                            Text(StarterRecipe.localized(step.text))
                                .font(.system(.body, design: .serif))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding()
        }
        .background(paperBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                if bookRecipe == nil {
                    onAdd()
                } else {
                    onOpen()
                }
            } label: {
                Text(bookRecipe == nil ? "Add to my book" : "Open in my book")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding()
            .background(.bar)
        }
    }
}

#Preview {
    RecipeIdeasView()
        .environment(AppNavigator())
}
