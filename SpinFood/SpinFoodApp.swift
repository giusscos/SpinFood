import SwiftUI
import SwiftData

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
            FoodWasteModel.self,
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
        AppLanguage.registerDefault()
        NotificationManager.shared.startHandlingTaps()
        #if DEBUG && targetEnvironment(simulator)
        ScreenshotSeed.seedIfRequested(in: sharedModelContainer.mainContext)
        #endif
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
