import Foundation
import SwiftData

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var isLoading = false

    func complete(
        _ task: TaskModel,
        notes: String? = nil,
        context: ModelContext,
        syncEngine: SyncEngine,
        notificationScheduler: NotificationScheduler
    ) async {
        let completion = CompletionModel(completedAt: Date(), notes: notes)
        completion.task = task
        task.completions.append(completion)
        task.lastCompleted = Date()
        task.nextDue = computeNextDue(frequency: task.frequency, season: task.season)
        try? context.save()

        notificationScheduler.cancel(for: task)
        notificationScheduler.schedule(task)

        if let taskId = task.id {
            await syncEngine.syncCompletion(taskId: taskId, notes: notes)
        }
    }

    func dismiss(_ task: TaskModel, context: ModelContext, notificationScheduler: NotificationScheduler) {
        task.isDismissed = true
        notificationScheduler.cancel(for: task)
        try? context.save()
    }

    private func computeNextDue(frequency: String, season: String?) -> Date {
        let calendar = Calendar.current
        let now = Date()

        if let season {
            let monthMap = ["spring": 4, "summer": 7, "fall": 10, "winter": 1]
            if let month = monthMap[season] {
                var components = calendar.dateComponents([.year], from: now)
                components.month = month
                components.day = 1
                components.hour = 9
                if var candidate = calendar.date(from: components), candidate <= now {
                    candidate = calendar.date(byAdding: .year, value: 1, to: candidate)!
                    return candidate
                } else if let candidate = calendar.date(from: components) {
                    return candidate
                }
            }
        }

        let daysMap = ["weekly": 7, "monthly": 30, "quarterly": 90, "twice_yearly": 182, "annually": 365]
        let days = daysMap[frequency] ?? 365
        return calendar.date(byAdding: .day, value: days, to: now)!
    }
}
