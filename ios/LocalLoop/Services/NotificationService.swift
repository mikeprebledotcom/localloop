import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func notifyRecordingStopped(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Recording Stopped"
        content.body = "Local Loop stopped recording at \(time.formatted(date: .omitted, time: .shortened)). Tap to restart."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "recording-stopped-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifyUploadComplete(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Upload Complete"
        content.body = "\(count) audio chunk(s) uploaded to Google Drive."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "upload-complete-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
