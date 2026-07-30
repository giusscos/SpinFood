import Foundation
import UserNotifications
import SwiftUI
import AlarmKit

/// Schedules a system alarm that rings when the cook timer finishes.
/// Uses AlarmKit on iOS 26+ (breaks through Silent / Focus); falls back to a local notification otherwise.
enum CookTimerAlarmScheduler {
    /// Stable ID so the app and Live Activity intents manage the same alarm.
    static let alarmID = UUID(uuidString: "C00C71E0-A1A2-4B3C-8D9E-F00D71E00001")!
    private static let notificationID = "cook-timer-complete"

    static func schedule(after interval: TimeInterval, label: String) {
        guard interval > 0 else { return }
        cancel()

        if #available(iOS 26.0, *) {
            Task { await scheduleAlarmKit(after: interval, label: label) }
        } else {
            scheduleNotification(after: interval, label: label)
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])

        if #available(iOS 26.0, *) {
            // cancel = not yet fired; stop = currently alerting
            try? AlarmManager.shared.cancel(id: alarmID)
            try? AlarmManager.shared.stop(id: alarmID)
        }
    }

    /// Prompts for AlarmKit authorization (iOS 26+). Returns `true` when authorized.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await manager.requestAuthorization() == .authorized
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - AlarmKit

    @available(iOS 26.0, *)
    private static func scheduleAlarmKit(after interval: TimeInterval, label: String) async {
        let manager = AlarmManager.shared

        do {
            let authorized = await requestAuthorization()
            guard authorized else {
                scheduleNotification(after: interval, label: label)
                return
            }

            let title = label.isEmpty
                ? String(localized: "Timer Done")
                : label

            let alert: AlarmPresentation.Alert
            if #available(iOS 26.1, *) {
                alert = AlarmPresentation.Alert(
                    title: LocalizedStringResource(stringLiteral: title)
                )
            } else {
                alert = AlarmPresentation.Alert(
                    title: LocalizedStringResource(stringLiteral: title),
                    stopButton: AlarmButton(
                        text: "Done",
                        textColor: .white,
                        systemImageName: "checkmark"
                    )
                )
            }

            let attributes = AlarmAttributes<CookTimerAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                metadata: CookTimerAlarmMetadata(),
                tintColor: .orange
            )

            let endDate = Date().addingTimeInterval(interval)
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: .fixed(endDate),
                attributes: attributes,
                sound: .default
            )

            _ = try await manager.schedule(id: alarmID, configuration: configuration)
        } catch {
            scheduleNotification(after: interval, label: label)
        }
    }

    // MARK: - Fallback notification

    private static func scheduleNotification(after interval: TimeInterval, label: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Timer Done")
        content.body = "\(label) — " + String(localized: "Timer finished. Time to move on!")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        )
    }
}

@available(iOS 26.0, *)
struct CookTimerAlarmMetadata: AlarmMetadata {}
