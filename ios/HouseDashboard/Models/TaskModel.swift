import Foundation
import SwiftData

@Model
final class TaskModel {
    @Attribute(.unique) var id: Int?
    var name: String
    var frequency: String
    var season: String?
    var dueDate: Date?
    var lastCompleted: Date?
    var nextDue: Date?
    var source: String
    var reason: String?
    var isDismissed: Bool
    var updatedAt: Date
    var createdAt: Date
    var needsSync: Bool

    var house: HouseModel?

    @Relationship(deleteRule: .cascade) var completions: [CompletionModel]

    init(
        name: String,
        frequency: String,
        season: String? = nil,
        nextDue: Date? = nil,
        source: String = "rule",
        reason: String? = nil
    ) {
        self.name = name
        self.frequency = frequency
        self.season = season
        self.nextDue = nextDue
        self.source = source
        self.reason = reason
        self.isDismissed = false
        self.updatedAt = Date()
        self.createdAt = Date()
        self.needsSync = false
        self.completions = []
    }

    var isOverdue: Bool {
        guard let nextDue else { return false }
        return nextDue < Date()
    }

    var isDueSoon: Bool {
        guard let nextDue else { return false }
        return nextDue < Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    }

    var statusColor: String {
        if isOverdue { return "red" }
        if isDueSoon { return "orange" }
        return "green"
    }
}
