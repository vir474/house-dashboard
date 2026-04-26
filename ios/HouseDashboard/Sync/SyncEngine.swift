import Combine
import Foundation
import Network
import SwiftData

@MainActor
final class SyncEngine: ObservableObject {
    @Published var isOnline = false
    @Published var isSyncing = false
    @Published var lastSyncAt: Date?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "sync.monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    // MARK: - House sync

    func syncHouse(_ house: HouseModel) async {
        guard isOnline, house.needsSync else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let body = HouseCreateRequest(
                name: house.name,
                yearBuilt: house.yearBuilt,
                zipCode: house.zipCode,
                hvacType: house.hvacType,
                roofMaterial: house.roofMaterial,
                hasFireplace: house.hasFireplace,
                hasPool: house.hasPool,
                hasBasement: house.hasBasement,
                waterHeaterAge: house.waterHeaterAge
            )
            let response = try await APIClient.post(path: "/houses/", body: body, as: HouseResponse.self)
            house.id = response.id
            house.needsSync = false
            lastSyncAt = Date()

            // Fetch server-generated tasks
            let taskResponses = try await APIClient.get(
                path: "/houses/\(response.id)/tasks",
                as: [TaskResponse].self
            )
            applyRemoteTasks(taskResponses, to: house)
        } catch {
            // Will retry next time isOnline flips to true
        }
    }

    // MARK: - Task completion sync

    func syncCompletion(taskId: Int, notes: String?) async {
        guard isOnline else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            _ = try await APIClient.post(
                path: "/tasks/\(taskId)/complete",
                body: CompleteTaskRequest(notes: notes),
                as: CompletionResponse.self
            )
            lastSyncAt = Date()
        } catch {
            // Completion already saved locally — will retry
        }
    }

    // MARK: - LLM suggestions

    func fetchSuggestions(for house: HouseModel) async -> [TaskResponse] {
        guard isOnline, let houseId = house.id else { return [] }
        isSyncing = true
        defer { isSyncing = false }

        do {
            return try await APIClient.post(
                path: "/houses/\(houseId)/tasks/suggest",
                body: EmptyBody(),
                as: [TaskResponse].self
            )
        } catch {
            return []
        }
    }

    // MARK: - Private helpers

    private func applyRemoteTasks(_ responses: [TaskResponse], to house: HouseModel) {
        for r in responses {
            if !house.tasks.contains(where: { $0.id == r.id }) {
                let task = TaskModel(
                    name: r.name,
                    frequency: r.frequency,
                    season: r.season,
                    nextDue: r.nextDue,
                    source: r.source,
                    reason: r.reason
                )
                task.id = r.id
                task.needsSync = false
                house.tasks.append(task)
            }
        }
    }
}

private struct EmptyBody: Encodable {}
