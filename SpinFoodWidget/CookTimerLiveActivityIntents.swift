import AppIntents
import ActivityKit
import Foundation

struct ToggleCookTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Play or Pause Timer"
    static var description = IntentDescription("Play or pause the cooking timer")

    func perform() async throws -> some IntentResult {
        for activity in Activity<CookTimerAttributes>.activities {
            let state = activity.content.state
            if state.isRunning {
                let remaining = max(0, state.endDate?.timeIntervalSinceNow ?? state.remainingWhenPaused)
                let paused = CookTimerAttributes.ContentState(
                    endDate: nil,
                    remainingWhenPaused: remaining,
                    isRunning: false,
                    total: state.total
                )
                await activity.update(.init(state: paused, staleDate: nil))
            } else {
                let remaining = state.remainingWhenPaused
                guard remaining > 0 else { continue }
                let endDate = Date().addingTimeInterval(remaining)
                let running = CookTimerAttributes.ContentState(
                    endDate: endDate,
                    remainingWhenPaused: remaining,
                    isRunning: true,
                    total: state.total
                )
                await activity.update(.init(state: running, staleDate: endDate))
            }
        }
        return .result()
    }
}

struct DismissCookTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Remove Timer"
    static var description = IntentDescription("Remove the cooking timer")

    func perform() async throws -> some IntentResult {
        for activity in Activity<CookTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
