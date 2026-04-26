import Foundation
import SwiftData

@MainActor
final class HouseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestionCount = 0

    func createHouse(
        _ payload: HouseModel,
        context: ModelContext,
        syncEngine: SyncEngine,
        notificationScheduler: NotificationScheduler
    ) async {
        isLoading = true
        defer { isLoading = false }

        context.insert(payload)
        try? context.save()

        // Sync to backend; backend will run rule engine and return tasks
        await syncEngine.syncHouse(payload)

        // Schedule local notifications for all generated tasks
        notificationScheduler.scheduleAll(for: payload.tasks)
    }

    func fetchSuggestions(
        for house: HouseModel,
        context: ModelContext,
        syncEngine: SyncEngine,
        notificationScheduler: NotificationScheduler
    ) async {
        isLoading = true
        defer { isLoading = false }

        let suggestions = await syncEngine.fetchSuggestions(for: house)
        suggestionCount = suggestions.count
        try? context.save()
        notificationScheduler.scheduleAll(for: house.tasks)
    }
}
