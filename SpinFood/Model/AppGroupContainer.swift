import Foundation

enum AppGroupContainer {
    static let identifier = "group.giusscos.SpinFood"
    static let cloudKitContainerIdentifier = "iCloud.giusscos.SpinFood"
    static let widgetSnapshotKey = "widgetSnapshot"
    static let pendingCookRecipeIDKey = "pendingCookRecipeID"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
