import SwiftUI

struct FloatingCookTimerBanner: View {
    var timer: CookTimerController

    private var progress: Double {
        let total = max(timer.total, 1)
        return max(0, min(1, 1 - timer.remaining / total))
    }

    var body: some View {
        if timer.isVisible {
            HStack(spacing: 12) {
                circularProgress(size: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.label)
                        .font(.system(.caption, design: .serif).weight(.semibold))
                        .lineLimit(1)
                    Text(timeString(timer.remaining))
                        .font(.system(.title3, design: .serif).monospacedDigit().weight(.bold))
                        .foregroundStyle(timer.remaining <= 30 && timer.isRunning ? .red : .primary)
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 8)

                Button {
                    timer.toggle()
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button {
                    timer.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.orange.opacity(0.25), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func circularProgress(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.25), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Timer progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }

    private func timeString(_ t: TimeInterval) -> String {
        let clamped = max(0, Int(t))
        let h = clamped / 3600
        let m = (clamped % 3600) / 60
        let s = clamped % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
