import SwiftUI
import SwiftData

struct CookRecipeStepByStepView: View {
    @Environment(\.dismiss) var dismiss

    var recipe: RecipeModel
    var steps: [StepRecipe]
    var servingScale: Double = 1

    @State private var showEatConfirmation = false
    @State private var didConfirmEat = false
    @State private var cookTimer = CookTimerController()

    var body: some View {
        ZStack(alignment: .bottom) {
            StepBookCurlView(
                steps: steps,
                ingredients: recipe.ingredients ?? [],
                mode: .cook,
                servingScale: servingScale,
                startPage: recipe.lastStepIndex,
                onPageChange: { page in
                    recipe.lastStepIndex = page
                    handlePageChange(page)
                },
                onDismiss: {
                    cookTimer.dismiss()
                    dismiss()
                },
                onFinishCooking: {
                    cookTimer.dismiss()
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        showEatConfirmation = true
                    } else {
                        recipe.finishCookingSession()
                        dismiss()
                    }
                }
            )
            .ignoresSafeArea()
            .environment(\.cookTimer, cookTimer)

            FloatingCookTimerBanner(timer: cookTimer)
                .safeAreaPadding(.bottom, 12)
                .animation(.spring(response: 0.35), value: cookTimer.isVisible)
        }
        .onAppear {
            handlePageChange(recipe.lastStepIndex)
        }
        .sheet(isPresented: $showEatConfirmation) {
            RecipeConfirmEatView(
                recipe: recipe,
                initialServings: max(1, Int(round(Double(max(1, recipe.servings)) * servingScale))),
                allowsServingsAdjustment: false,
                onConfirmed: { didConfirmEat = true }
            )
            .onDisappear {
                if !didConfirmEat {
                    // Keep session in progress; resume on the last real step next time.
                    recipe.lastStepIndex = max(0, steps.count - 1)
                }
                dismiss()
            }
        }
    }

    private func handlePageChange(_ page: Int) {
        guard page >= 0, page < steps.count else { return }
        cookTimer.autoStartIfNeeded(for: steps[page])
    }
}

#Preview {
    CookRecipeStepByStepView(recipe: RecipeModel(name: "Recipe"), steps: [StepRecipe(text: "Step 1")])
}
