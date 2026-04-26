import SwiftData
import SwiftUI

struct ContentView: View {
    @Query private var houses: [HouseModel]
    @EnvironmentObject var syncEngine: SyncEngine
    @EnvironmentObject var notificationScheduler: NotificationScheduler

    var body: some View {
        Group {
            if houses.isEmpty {
                OnboardingView()
            } else {
                DashboardView(house: houses[0])
            }
        }
        .task {
            await notificationScheduler.requestPermission()
        }
    }
}
