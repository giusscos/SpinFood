import AppIntents
import WidgetKit

struct NextCookableRecipeIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Ready Recipe"
    static var description = IntentDescription("Show another recipe you can cook now.")
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        WidgetSnapshotStore.advanceCookableRecipe()
        return .result()
    }
}

struct StartCookFromWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Cooking"
    static var description = IntentDescription("Open Foo and start cooking step by step.")
    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @Parameter(title: "Recipe ID")
    var recipeID: String

    init() {
        self.recipeID = ""
    }

    init(recipeID: String) {
        self.recipeID = recipeID
    }

    func perform() async throws -> some IntentResult {
        guard !recipeID.isEmpty else { return .result() }
        AppGroupContainer.sharedDefaults.set(recipeID, forKey: AppGroupContainer.pendingCookRecipeIDKey)
        return .result()
    }
}
