import SwiftData
import SwiftUI

@main
struct HouseDashboardApp: App {
    @StateObject private var syncEngine = SyncEngine()
    @StateObject private var notificationScheduler = NotificationScheduler()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([HouseModel.self, TaskModel.self, CompletionModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(syncEngine)
                .environmentObject(notificationScheduler)
        }
        .modelContainer(sharedModelContainer)
    }
}
