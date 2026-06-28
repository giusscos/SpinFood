import SwiftUI

struct BookRecipePage: View {
    let recipe: RecipeModel
    let pageNumber: Int
    var onEdit: () -> Void
    var onBack: () -> Void
    var onDelete: () -> Void = {}

    @State private var activeSheet: ActiveRecipeDetailSheet?
    @State private var showDeleteConfirmation = false

    private var pageBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1)
        })
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        recipePhoto
                        titleSection
                        divider
                        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            ingredientsSection(ingredients)
                            divider
                        }
                        cookSection
                        Spacer().frame(height: 48)
                    }
                }

                Text("\(pageNumber)")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 12)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Index")
                                .font(.system(.subheadline, design: .serif))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onEdit) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26, *) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .tint(.red)
                        .buttonStyle(.glassProminent)
                    } else {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .tint(.red)
                    }
                }
            }
            .confirmationDialog("Delete Recipe", isPresented: $showDeleteConfirmation) {
                Button("Delete Recipe", role: .destructive) {
                    onBack()
                    onDelete()
                }
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .confirmEat:
                    RecipeConfirmEatView(recipe: recipe)
                case .cookNow(let steps):
                    CookRecipeStepByStepView(recipe: recipe, steps: steps)
                case .steps(let steps):
                    StepBookCurlView(
                        steps: steps,
                        ingredients: recipe.ingredients ?? [],
                        mode: .view,
                        onDismiss: { activeSheet = nil }
                    )
                    .ignoresSafeArea()
                }
            }
        }
    }

    // MARK: - Photo

    @ViewBuilder
    private var recipePhoto: some View {
        HStack {
            Spacer()
            if let data = recipe.image, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 200)
                    .clipped()
                    .padding(8)
                    .background(.white)
                    .shadow(color: .black.opacity(0.18), radius: 10, x: 1, y: 4)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.6))
                            .frame(width: 56, height: 16)
                            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                            .offset(y: -8)
                    }
                    .rotationEffect(.degrees(-1.2))
            } else {
                ZStack {
                    Color(UIColor.secondarySystemFill)

                    Image(systemName: "camera")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 280, height: 200)
                .padding(8)
                .background(.white)
                .shadow(color: .black.opacity(0.18), radius: 10, x: 1, y: 4)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.6))
                        .frame(width: 56, height: 16)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .offset(y: -8)
                }
                .rotationEffect(.degrees(-1.2))
            }
            Spacer()
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.name)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .fixedSize(horizontal: false, vertical: true)

            if !recipe.descriptionRecipe.isEmpty {
                Text(recipe.descriptionRecipe)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if recipe.duration > 0 || recipe.servings > 0 || recipe.rating > 0 {
                HStack(spacing: 20) {
                    if recipe.duration > 0 {
                        metaBadge(label: "TIME", value: recipe.duration.formatted)
                    }
                    if recipe.servings > 0 {
                        metaBadge(label: "SERVES", value: "\(recipe.servings)")
                    }
                    if recipe.rating > 0 {
                        metaBadge(label: "RATING", value: String(repeating: "★", count: recipe.rating))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(height: 1)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
    }

    // MARK: - Ingredients

    private func ingredientsSection(_ ingredients: [RecipeFoodModel]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ingredients")
                .font(.system(.title3, design: .serif).weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { item in
                    if let food = item.ingredient {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 5, height: 5)

                            Text("\(food.emoji.isEmpty ? "" : food.emoji + " ")\(food.name)")
                                .font(.system(.body, design: .serif))

                            Spacer()

                            Text("\(item.quantityNeeded.formatted()) \(food.unit.abbreviation)")
                                .font(.system(.callout, design: .serif))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Cook

    private var cookSection: some View {
        VStack(spacing: 12) {
            if !recipe.canCook, !(recipe.ingredients?.isEmpty ?? true) {
                Text("Missing \(recipe.missingIngredients.count) ingredient\(recipe.missingIngredients.count == 1 ? "" : "s")")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(spacing: 12) {
                if let steps = recipe.steps, !steps.isEmpty {
                    Button { activeSheet = .cookNow(steps) } label: {
                        Label("Cook Step by Step", systemImage: "frying.pan")
                            .font(.system(.callout, design: .serif).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                recipe.canCook ? Color.accentColor : Color.secondary.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(recipe.canCook ? .white : .secondary)
                    }

                    Button { activeSheet = .steps(steps) } label: {
                        Label("View Steps", systemImage: "book.pages")
                            .font(.system(.callout, design: .serif).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.primary)
                    }
                }

                Button { activeSheet = .confirmEat } label: {
                    Label("Mark as Eaten", systemImage: "checkmark")
                        .font(.system(.callout, design: .serif).weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func metaBadge(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .serif))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            Text(value)
                .font(.system(.callout, design: .serif))
        }
    }
}
