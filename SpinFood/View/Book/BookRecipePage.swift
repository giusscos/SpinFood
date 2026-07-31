import SwiftUI

enum ActiveRecipeDetailSheet: Identifiable {
    case confirmEat
    case cookNow([StepRecipe])
    case steps([StepRecipe])

    var id: String {
        switch self {
        case .confirmEat:
            return "confirmEat"
        case .cookNow(let steps):
            return "cookNow-\(steps.count)"
        case .steps(let steps):
            return "steps-\(steps.count)"
        }
    }
}

struct BookRecipePage: View {
    let recipe: RecipeModel
    let pageNumber: Int
    var onEdit: () -> Void
    var onBack: () -> Void
    var onDelete: () -> Void = {}

    @State private var activeSheet: ActiveRecipeDetailSheet?
    @State private var showDeleteConfirmation = false
    @State private var sharingItems: [Any] = []
    @State private var showShareSheet = false
    @State private var exportErrorMessage: String? = nil

    // Cook serving picker (shown as a sheet BEFORE the fullScreenCover opens)
    @State private var showCookServingPicker = false
    @State private var pendingCookSteps: [StepRecipe]? = nil
    @State private var cookServings: Int = 1
    @State private var cookServingScale: Double = 1
    @State private var cookConfirmed = false
    @State private var cookLimitAlertMessage: String? = nil

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
                    Button {
                        shareRecipe()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
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
                    onDelete()
                }
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(item: $activeSheet) { sheet in
                switch sheet {
                case .confirmEat:
                    RecipeConfirmEatView(recipe: recipe)
                case .cookNow(let steps):
                    CookRecipeStepByStepView(
                        recipe: recipe,
                        steps: steps,
                        servingScale: recipe.lastCookServingScale
                    )
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
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: sharingItems)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showCookServingPicker, onDismiss: {
                if cookConfirmed, let steps = pendingCookSteps {
                    // Defer so the sheet can finish dismissing before the full-screen cover presents.
                    DispatchQueue.main.async {
                        activeSheet = .cookNow(steps)
                    }
                }
                cookConfirmed = false
                pendingCookSteps = nil
            }) {
                CookServingPickerSheet(
                    recipe: recipe,
                    selectedServings: $cookServings,
                    maxServings: max(1, min(20, recipe.maxCookableServings)),
                    onConfirm: {
                        let maxAllowed = max(1, recipe.maxCookableServings)
                        if cookServings > maxAllowed {
                            cookLimitAlertMessage = String(localized: "You only have enough ingredients for \(maxAllowed) serving\(maxAllowed == 1 ? "" : "s").")
                            cookServings = maxAllowed
                            return
                        }
                        cookServingScale = Double(cookServings) / Double(max(1, recipe.servings))
                        recipe.lastCookServingScale = cookServingScale
                        recipe.lastStepIndex = 0
                        recipe.cookingInProgress = true
                        cookConfirmed = true
                        showCookServingPicker = false
                    },
                    onCancel: { showCookServingPicker = false }
                )
                .presentationDetents([.height(320)])
                .interactiveDismissDisabled()
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { exportErrorMessage = nil }
            } message: {
                Text(exportErrorMessage ?? "")
            }
            .alert("Can't Cook", isPresented: Binding(
                get: { cookLimitAlertMessage != nil },
                set: { if !$0 { cookLimitAlertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { cookLimitAlertMessage = nil }
            } message: {
                Text(cookLimitAlertMessage ?? "")
            }
        }
    }

    // MARK: - Share

    private func shareRecipe() {
        do {
            let url = try RecipeTransfer.export(recipe)
            sharingItems = [url]
            showShareSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
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
                    if let difficulty = recipe.difficulty {
                        metaBadge(label: "LEVEL", value: difficulty.localizedName)
                    }
                }
                .padding(.top, 4)
            }

            if !recipe.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recipe.tags, id: \.self) { tag in
                            Label(tag.localizedName, systemImage: tag.icon)
                                .font(.system(size: 11, design: .rounded).weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(.capsule)
                        }
                    }
                }
                .padding(.top, 2)
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
                        let perServing = item.quantityNeeded / Decimal(max(1, recipe.servings))
                        let insufficient = food.currentQuantity < perServing
                        HStack(spacing: 10) {
                            Circle()
                                .fill(insufficient ? Color.orange.opacity(0.7) : Color.secondary.opacity(0.3))
                                .frame(width: 5, height: 5)

                            Text("\(food.emoji.isEmpty ? "" : food.emoji + " ")\(food.name)")
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(insufficient ? .orange : .primary)

                            Spacer()

                            Text("\(item.quantityNeeded.formatted()) \(food.unit.abbreviation)")
                                .font(.system(.callout, design: .serif))
                                .foregroundStyle(insufficient ? .orange : .secondary)
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
                    Button {
                        startCookStepByStep(steps: steps)
                    } label: {
                        Label(
                            recipe.cookingInProgress ? "Resume Cooking" : "Cook Step by Step",
                            systemImage: "frying.pan"
                        )
                            .font(.system(.callout, design: .serif).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                recipe.canCook || recipe.cookingInProgress
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(recipe.canCook || recipe.cookingInProgress ? .white : .secondary)
                            .contentTransition(.interpolate)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: recipe.cookingInProgress)
                    }

                    if recipe.cookingInProgress {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                recipe.finishCookingSession()
                            }
                        } label: {
                            Label("Reset Cooking Progress", systemImage: "arrow.counterclockwise")
                                .font(.system(.callout, design: .serif).weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(.primary)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
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
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: recipe.cookingInProgress)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func startCookStepByStep(steps: [StepRecipe]) {
        if recipe.cookingInProgress {
            cookServingScale = recipe.lastCookServingScale
            activeSheet = .cookNow(steps)
            return
        }

        pendingCookSteps = steps
        let maxAllowed = max(1, min(20, recipe.maxCookableServings))
        cookServings = min(max(1, recipe.servings), maxAllowed)
        showCookServingPicker = true
    }

    private func metaBadge(label: LocalizedStringKey, value: String) -> some View {
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

// MARK: - Cook Serving Picker Sheet

private struct CookServingPickerSheet: View {
    let recipe: RecipeModel
    @Binding var selectedServings: Int
    var maxServings: Int
    var onConfirm: () -> Void
    var onCancel: () -> Void

    private let paperColor = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    })

    private var scale: Double {
        Double(selectedServings) / Double(max(1, recipe.servings))
    }

    private var cappedMax: Int { max(1, maxServings) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("How many servings?")
                        .font(.system(.title3, design: .serif).weight(.semibold))
                    Text("Recipe makes \(recipe.servings)")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                HStack(spacing: 28) {
                    Button {
                        if selectedServings > 1 { selectedServings -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(selectedServings > 1 ? Color.accentColor : .secondary.opacity(0.2))
                    }
                    .disabled(selectedServings <= 1)

                    Text("\(selectedServings)")
                        .font(.system(size: 52, weight: .bold, design: .serif))
                        .monospacedDigit()
                        .frame(minWidth: 64)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: selectedServings)

                    Button {
                        if selectedServings < cappedMax { selectedServings += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(selectedServings < cappedMax ? Color.accentColor : .secondary.opacity(0.2))
                    }
                    .disabled(selectedServings >= cappedMax)
                }
                .buttonStyle(.borderless)

                VStack(spacing: 4) {
                    if selectedServings != recipe.servings {
                        Text("Scaling × \(String(format: "%.2g", scale)) from original")
                            .foregroundStyle(.orange)
                    }

                    Text("Up to \(cappedMax) based on your pantry")
                        .foregroundStyle(.secondary)
                }
                .font(.system(.caption, design: .rounded))

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(paperColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedServings > cappedMax {
                    selectedServings = cappedMax
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .font(.system(.body, design: .serif))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start Cooking", action: onConfirm)
                        .font(.system(.body, design: .serif).weight(.semibold))
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


