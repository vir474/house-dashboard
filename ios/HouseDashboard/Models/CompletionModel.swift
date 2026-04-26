import Foundation
import SwiftData

@Model
final class CompletionModel {
    @Attribute(.unique) var id: Int?
    var completedAt: Date
    var notes: String?
    var task: TaskModel?

    init(completedAt: Date = Date(), notes: String? = nil) {
        self.completedAt = completedAt
        self.notes = notes
    }
}
