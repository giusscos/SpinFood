import Foundation
import Observation
import ActivityKit

@Observable
final class CookTimerController {
    /// Used by Live Activity intents when the cook screen is open.
    static weak var sharedActive: CookTimerController?

    var label: String = ""
    var remaining: TimeInterval = 0
    var total: TimeInterval = 0
    var isRunning: Bool = false
    var isVisible: Bool = false
    var sourceStepID: UUID? = nil

    private var endDate: Date?
    private var tickTimer: Timer?
    private var liveActivity: Activity<CookTimerAttributes>?
    private var contentUpdatesTask: Task<Void, Never>?
    private var lastPushedState: CookTimerAttributes.ContentState?
    private var isEndingLocally = false
    private var lastEmittedSecond: Int = -1

    func start(duration: TimeInterval, label: String, stepID: UUID? = nil, auto: Bool = false) {
        guard duration > 0 else { return }
        // Don't interrupt an active timer with auto-start from another step
        if auto, isRunning, isVisible { return }

        Self.sharedActive = self
        stopTicking()
        CookTimerAlarmScheduler.cancel()

        self.label = label.isEmpty ? String(localized: "Timer") : label
        self.total = duration
        self.remaining = duration
        self.sourceStepID = stepID
        self.isVisible = true
        self.isRunning = true
        self.endDate = Date().addingTimeInterval(duration)
        self.lastEmittedSecond = -1

        CookTimerAlarmScheduler.schedule(after: duration, label: self.label)
        startTicking()
        startOrUpdateLiveActivity()
    }

    func pause() {
        guard isRunning else { return }
        syncRemainingFromEndDate()
        isRunning = false
        endDate = nil
        stopTicking()
        CookTimerAlarmScheduler.cancel()
        updateLiveActivity()
    }

    func resume() {
        guard !isRunning, remaining > 0 else { return }
        isRunning = true
        endDate = Date().addingTimeInterval(remaining)
        lastEmittedSecond = -1
        CookTimerAlarmScheduler.schedule(after: remaining, label: label)
        startTicking()
        updateLiveActivity()
    }

    func toggle() {
        isRunning ? pause() : resume()
    }

    func reset() {
        stopTicking()
        CookTimerAlarmScheduler.cancel()
        remaining = total
        isRunning = false
        endDate = nil
        updateLiveActivity()
    }

    func dismiss() {
        stopTicking()
        CookTimerAlarmScheduler.cancel()
        endLiveActivity()
        isRunning = false
        isVisible = false
        remaining = 0
        total = 0
        endDate = nil
        sourceStepID = nil
        label = ""
        if Self.sharedActive === self {
            Self.sharedActive = nil
        }
    }

    func autoStartIfNeeded(for step: StepRecipe) {
        guard step.hasSuggestedTimer else { return }
        if sourceStepID == step.id, isVisible { return }
        start(
            duration: step.suggestedDuration,
            label: String(localized: "Step timer"),
            stepID: step.id,
            auto: true
        )
    }

    // MARK: - Private

    private func startTicking() {
        stopTicking()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard isRunning else { return }
        syncRemainingFromEndDate()
        let second = Int(remaining)
        // Push once per second so Live Activity text can use padded MM:SS (Text(timerInterval:) cannot).
        if second != lastEmittedSecond {
            lastEmittedSecond = second
            updateLiveActivity()
        }
        if remaining <= 0 {
            remaining = 0
            isRunning = false
            endDate = nil
            stopTicking()
            updateLiveActivity(final: true)
        }
    }

    private func syncRemainingFromEndDate() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
    }

    // MARK: - Live Activity

    private func currentContentState() -> CookTimerAttributes.ContentState {
        CookTimerAttributes.ContentState(
            endDate: isRunning ? endDate : nil,
            remainingWhenPaused: remaining,
            isRunning: isRunning,
            total: total
        )
    }

    private func startOrUpdateLiveActivity() {
        Self.sharedActive = self
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = CookTimerAttributes(label: label)
        let state = currentContentState()

        if let liveActivity {
            // Attributes (label) can't be updated in place — restart when the timer name changes.
            if liveActivity.attributes.label != label {
                let old = liveActivity
                self.liveActivity = nil
                contentUpdatesTask?.cancel()
                Task {
                    await old.end(nil, dismissalPolicy: .immediate)
                    await MainActor.run { self.requestNewLiveActivity(attributes: attributes, state: state) }
                }
                return
            }
            pushUpdate(state)
            return
        }

        // End any leftover activities from a previous session
        for activity in Activity<CookTimerAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }

        requestNewLiveActivity(attributes: attributes, state: state)
    }

    private func requestNewLiveActivity(
        attributes: CookTimerAttributes,
        state: CookTimerAttributes.ContentState
    ) {
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: state.endDate),
                pushType: nil
            )
            liveActivity = activity
            lastPushedState = state
            observe(activity)
        } catch {
            // Live Activities may be disabled by the user or unavailable on this device.
            liveActivity = nil
        }
    }

    private func observe(_ activity: Activity<CookTimerAttributes>) {
        contentUpdatesTask?.cancel()
        contentUpdatesTask = Task { @MainActor [weak self] in
            for await content in activity.contentUpdates {
                guard let self else { return }
                self.applyRemoteStateIfNeeded(content.state)
            }
            guard let self, !self.isEndingLocally else { return }
            // Activity ended externally (e.g. Remove on Lock Screen / Dynamic Island).
            if self.isVisible {
                self.applyExternalDismiss()
            }
        }
    }

    private func applyRemoteStateIfNeeded(_ state: CookTimerAttributes.ContentState) {
        if let lastPushedState, lastPushedState == state {
            return
        }

        let wasRunning = isRunning
        isRunning = state.isRunning
        total = state.total
        endDate = state.endDate

        if state.isRunning, let endDate = state.endDate {
            remaining = max(0, endDate.timeIntervalSinceNow)
        } else {
            remaining = state.remainingWhenPaused
            endDate = nil
        }

        lastPushedState = state

        if isRunning {
            if !wasRunning {
                CookTimerAlarmScheduler.cancel()
                if remaining > 0 {
                    CookTimerAlarmScheduler.schedule(after: remaining, label: label)
                }
            }
            startTicking()
        } else {
            stopTicking()
            CookTimerAlarmScheduler.cancel()
        }
    }

    private func applyExternalDismiss() {
        stopTicking()
        CookTimerAlarmScheduler.cancel()
        contentUpdatesTask?.cancel()
        contentUpdatesTask = nil
        liveActivity = nil
        lastPushedState = nil
        isRunning = false
        isVisible = false
        remaining = 0
        total = 0
        endDate = nil
        sourceStepID = nil
        label = ""
        if Self.sharedActive === self {
            Self.sharedActive = nil
        }
    }

    private func pushUpdate(_ state: CookTimerAttributes.ContentState) {
        guard let liveActivity else { return }
        lastPushedState = state
        Task {
            await liveActivity.update(.init(state: state, staleDate: state.endDate))
        }
    }

    private func updateLiveActivity(final: Bool = false) {
        guard let liveActivity else {
            if !final, isVisible { startOrUpdateLiveActivity() }
            return
        }

        let state = currentContentState()
        lastPushedState = state
        Task {
            if final || (!isRunning && remaining <= 0) {
                isEndingLocally = true
                await liveActivity.end(
                    .init(state: state, staleDate: nil),
                    dismissalPolicy: .after(.now.addingTimeInterval(4))
                )
                await MainActor.run {
                    self.liveActivity = nil
                    self.contentUpdatesTask?.cancel()
                    self.contentUpdatesTask = nil
                    self.isEndingLocally = false
                }
            } else {
                await liveActivity.update(.init(state: state, staleDate: state.endDate))
            }
        }
    }

    private func endLiveActivity() {
        isEndingLocally = true
        contentUpdatesTask?.cancel()
        contentUpdatesTask = nil

        guard let liveActivity else {
            for activity in Activity<CookTimerAttributes>.activities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
            isEndingLocally = false
            return
        }
        let state = currentContentState()
        lastPushedState = state
        Task {
            await liveActivity.end(
                .init(state: state, staleDate: nil),
                dismissalPolicy: .immediate
            )
            await MainActor.run {
                self.liveActivity = nil
                self.isEndingLocally = false
            }
        }
        self.liveActivity = nil
    }
}
