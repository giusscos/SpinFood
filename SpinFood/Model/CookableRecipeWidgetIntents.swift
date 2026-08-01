import AppIntents
import Foundation

/// Handles the cook action from the Ready to Cook widget when the app is opened.
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
