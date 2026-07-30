import Foundation
import ActivityKit

struct CookTimerAttributes: ActivityAttributes {
    var label: String

    struct ContentState: Codable, Hashable {
        /// Countdown target while running. `nil` when paused.
        var endDate: Date?
        /// Remaining seconds when paused (or completed).
        var remainingWhenPaused: TimeInterval
        var isRunning: Bool
        var total: TimeInterval
    }
}
