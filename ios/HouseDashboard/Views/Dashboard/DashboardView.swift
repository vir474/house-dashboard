import SwiftData
import SwiftUI

struct DashboardView: View {
    let house: HouseModel
    @EnvironmentObject var syncEngine: SyncEngine
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @StateObject private var houseVM = HouseViewModel()
    @State private var selectedFilter: TaskFilter = .upcoming
    @State private var showSuggestSheet = false

    enum TaskFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case overdue = "Overdue"
        case all = "All"
    }

    private var filteredTasks: [TaskModel] {
        let active = house.tasks.filter { !$0.isDismissed }
        switch selectedFilter {
        case .upcoming: return active.filter { $0.isDueSoon || ($0.nextDue != nil && !$0.isOverdue) }.sorted { ($0.nextDue ?? .distantFuture) < ($1.nextDue ?? .distantFuture) }
        case .overdue:  return active.filter { $0.isOverdue }.sorted { ($0.nextDue ?? .distantFuture) < ($1.nextDue ?? .distantFuture) }
        case .all:      return active.sorted { ($0.nextDue ?? .distantFuture) < ($1.nextDue ?? .distantFuture) }
        }
    }

    private var overduCount: Int { house.tasks.filter { $0.isOverdue && !$0.isDismissed }.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats bar
                HStack(spacing: 24) {
                    StatBadge(label: "Overdue", value: overduCount, color: .red)
                    StatBadge(label: "Due this week", value: house.tasks.filter { $0.isDueSoon && !$0.isOverdue && !$0.isDismissed }.count, color: .orange)
                    StatBadge(label: "Total tasks", value: house.tasks.filter { !$0.isDismissed }.count, color: .blue)
                    Spacer()
                    if syncEngine.isSyncing {
                        ProgressView().scaleEffect(0.8)
                    } else if !syncEngine.isOnline {
                        Label("Offline", systemImage: "wifi.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.bar)

                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Task grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        ForEach(filteredTasks, id: \.persistentModelID) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                TaskCardView(task: task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(house.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSuggestSheet = true
                    } label: {
                        Label("AI Suggestions", systemImage: "sparkles")
                    }
                    .disabled(!syncEngine.isOnline || houseVM.isLoading)
                }
            }
            .sheet(isPresented: $showSuggestSheet) {
                SuggestSheet(house: house)
            }
        }
    }
}

private struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SuggestSheet: View {
    let house: HouseModel
    @EnvironmentObject var syncEngine: SyncEngine
    @EnvironmentObject var notificationScheduler: NotificationScheduler
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HouseViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)
                Text("AI Task Suggestions")
                    .font(.title2.bold())
                Text("Ollama will analyse your home profile and suggest additional maintenance tasks specific to your home.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if vm.isLoading {
                    ProgressView("Thinking...")
                } else {
                    Button("Generate suggestions") {
                        Task {
                            await vm.fetchSuggestions(
                                for: house,
                                context: context,
                                syncEngine: syncEngine,
                                notificationScheduler: notificationScheduler
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Enhance my plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
