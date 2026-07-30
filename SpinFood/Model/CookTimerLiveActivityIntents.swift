import AppIntents
import ActivityKit
import Foundation

struct ToggleCookTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Play or Pause Timer"
    static var description = IntentDescription("Play or pause the cooking timer")

    func perform() async throws -> some IntentResult {
        // Prefer the in-app controller when cooking is open so notifications stay in sync.
        if await MainActor.run(body: { CookTimerController.sharedActive != nil }) {
            await MainActor.run { CookTimerController.sharedActive?.toggle() }
            return .result()
        }

        for activity in Activity<CookTimerAttributes>.activities {
            let state = activity.content.state
            let label = activity.attributes.label
            if state.isRunning {
                let remaining = max(0, state.endDate?.timeIntervalSinceNow ?? state.remainingWhenPaused)
                let paused = CookTimerAttributes.ContentState(
                    endDate: nil,
                    remainingWhenPaused: remaining,
                    isRunning: false,
                    total: state.total
                )
                await activity.update(.init(state: paused, staleDate: nil))
                CookTimerAlarmScheduler.cancel()
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
                CookTimerAlarmScheduler.schedule(after: remaining, label: label)
            }
        }
        return .result()
    }
}

struct DismissCookTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Remove Timer"
    static var description = IntentDescription("Remove the cooking timer")

    func perform() async throws -> some IntentResult {
        if await MainActor.run(body: { CookTimerController.sharedActive != nil }) {
            await MainActor.run { CookTimerController.sharedActive?.dismiss() }
            return .result()
        }

        CookTimerAlarmScheduler.cancel()
        for activity in Activity<CookTimerAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
