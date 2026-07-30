import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

struct CookTimerLiveActivity: Widget {
    /// Shared leading inset so the top symbol and bottom title align.
    private let expandedLeadingPadding: CGFloat = 4

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookTimerAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    circularProgress(context: context, size: 32)
                        .padding(.leading, expandedLeadingPadding)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdownText(context: context)
                        .font(.title.monospacedDigit().weight(.bold))
                        .foregroundStyle(context.state.isRunning ? .orange : .secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(context.attributes.label)
                            .font(.title3.weight(.semibold))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, expandedLeadingPadding)

                        controlButtons(isRunning: context.state.isRunning)
                    }
                }
            } compactLeading: {
                circularProgress(context: context, size: 28)
            } compactTrailing: {
                countdownText(context: context)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(minWidth: 40)
            } minimal: {
                circularProgress(context: context, size: 28)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<CookTimerAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                circularProgress(context: context, size: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.label)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(context.state.isRunning ? "Cooking timer" : "Paused")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer(minLength: 8)

                countdownText(context: context)
                    .font(.title.monospacedDigit().weight(.bold))
                    .foregroundStyle(context.state.isRunning ? .orange : .white.opacity(0.8))
            }

            HStack(spacing: 12) {
                Button(intent: ToggleCookTimerIntent()) {
                    Label(
                        context.state.isRunning ? "Pause" : "Play",
                        systemImage: context.state.isRunning ? "pause.fill" : "play.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(Color.orange, in: Capsule())
                .foregroundStyle(.white)

                Button(intent: DismissCookTimerIntent()) {
                    Label("Remove", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(Color.white.opacity(0.15), in: Capsule())
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func controlButtons(isRunning: Bool) -> some View {
        HStack(spacing: 12) {
            Button(intent: ToggleCookTimerIntent()) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.2), in: Circle())
            }
            .buttonStyle(.plain)

            Button(intent: DismissCookTimerIntent()) {
                Image(systemName: "xmark")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    /// Uses system timer-interval progress so the ring keeps updating outside the app.
    @ViewBuilder
    private func circularProgress(
        context: ActivityViewContext<CookTimerAttributes>,
        size: CGFloat
    ) -> some View {
        let total = max(context.state.total, 1)

        Group {
            if context.state.isRunning, let endDate = context.state.endDate, endDate > .now {
                let startDate = endDate.addingTimeInterval(-total)
                ProgressView(timerInterval: startDate...endDate, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .progressViewStyle(.circular)
                .tint(.orange)
            } else {
                let progress = max(0, min(1, 1 - context.state.remainingWhenPaused / total))
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
                    .tint(.orange)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(size / 36)
        .frame(width: size, height: size)
    }

    /// Padded MM:SS / HH:MM:SS — Live Activity `Text(timerInterval:)` cannot zero-pad minutes.
    @ViewBuilder
    private func countdownText(context: ActivityViewContext<CookTimerAttributes>) -> some View {
        let showsHours = context.state.total >= 3600
        let remaining: TimeInterval = {
            if context.state.isRunning, let endDate = context.state.endDate {
                return max(0, endDate.timeIntervalSinceNow)
            }
            return context.state.remainingWhenPaused
        }()

        Text(Self.formatDuration(remaining, showsHours: showsHours))
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.default, value: Int(remaining))
    }

    private static func formatDuration(_ t: TimeInterval, showsHours: Bool) -> String {
        let clamped = max(0, Int(t))
        let h = clamped / 3600
        let m = (clamped % 3600) / 60
        let s = clamped % 60
        if showsHours || h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
