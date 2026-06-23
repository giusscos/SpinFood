import SwiftUI
import SwiftData

struct CookRecipeStepByStepView: View {
    @Environment(\.dismiss) var dismiss

    var recipe: RecipeModel
    var steps: [StepRecipe]

    @State private var showEatConfirmation = false

    var body: some View {
        StepBookCurlView(
            steps: steps,
            ingredients: recipe.ingredients ?? [],
            mode: .cook,
            startPage: recipe.lastStepIndex,
            onPageChange: { page in
                recipe.lastStepIndex = page
            },
            onDismiss: { dismiss() },
            onFinishCooking: {
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    showEatConfirmation = true
                } else {
                    dismiss()
                }
            }
        )
        .ignoresSafeArea()
        .sheet(isPresented: $showEatConfirmation) {
            RecipeConfirmEatView(recipe: recipe)
                .onDisappear { dismiss() }
        }
    }
}

#Preview {
    CookRecipeStepByStepView(recipe: RecipeModel(name: "Recipe"), steps: [StepRecipe(text: "Step 1")])
}
