import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler: ObservableObject {
    func requestPermission() async {
        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleAll(for tasks: [TaskModel]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for task in tasks where !task.isDismissed {
            schedule(task)
        }
    }

    func schedule(_ task: TaskModel) {
        guard let nextDue = task.nextDue, nextDue > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "House Task Due"
        content.body = task.name
        content.sound = .default
        content.userInfo = ["task_id": task.id ?? -1]

        // Also fire a warning 3 days before
        if let warningDate = Calendar.current.date(byAdding: .day, value: -3, to: nextDue),
           warningDate > Date() {
            schedule(content: content, at: warningDate, id: "warn-\(task.id ?? 0)-\(task.name.hashValue)")
        }

        schedule(content: content, at: nextDue, id: "due-\(task.id ?? 0)-\(task.name.hashValue)")
    }

    func cancel(for task: TaskModel) {
        let ids = [
            "warn-\(task.id ?? 0)-\(task.name.hashValue)",
            "due-\(task.id ?? 0)-\(task.name.hashValue)"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func schedule(content: UNMutableNotificationContent, at date: Date, id: String) {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
