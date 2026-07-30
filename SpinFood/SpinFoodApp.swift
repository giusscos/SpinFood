import SwiftUI
import SwiftData
import TipKit

@main
struct SpinFoodApp: App {
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "en"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecipeModel.self,
            StepRecipe.self,
            StepBlock.self,
            FoodModel.self,
            RecipeFoodModel.self,
            FoodConsumptionModel.self,
            FoodRefillModel.self,
            MealPlanEntry.self,
        ])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(AppGroupContainer.cloudKitContainerIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // CloudKit may be unavailable (no iCloud account / simulator). Fall back to local store.
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    init() {
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: selectedLanguage))
                .onAppear {
                    UITextField.appearance().clearButtonMode = .whileEditing
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
