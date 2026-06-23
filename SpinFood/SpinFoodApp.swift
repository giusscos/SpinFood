import SwiftUI
import SwiftData

@main
struct SpinFoodApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecipeModel.self,
            StepRecipe.self,
            StepBlock.self,
            FoodModel.self,
            RecipeFoodModel.self,
            FoodConsumptionModel.self,
            FoodRefillModel.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
