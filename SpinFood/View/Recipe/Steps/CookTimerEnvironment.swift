import SwiftUI

private struct CookTimerEnvironmentKey: EnvironmentKey {
    static let defaultValue: CookTimerController? = nil
}

extension EnvironmentValues {
    var cookTimer: CookTimerController? {
        get { self[CookTimerEnvironmentKey.self] }
        set { self[CookTimerEnvironmentKey.self] = newValue }
    }
}
