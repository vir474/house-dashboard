import Foundation

// MARK: - Request bodies

struct HouseCreateRequest: Encodable {
    let name: String
    let yearBuilt: Int?
    let zipCode: String?
    let hvacType: String?
    let roofMaterial: String?
    let hasFireplace: Bool
    let hasPool: Bool
    let hasBasement: Bool
    let waterHeaterAge: Int?
}

struct CompleteTaskRequest: Encodable {
    let notes: String?
}

// MARK: - Response bodies

struct HouseResponse: Decodable {
    let id: Int
    let name: String
    let yearBuilt: Int?
    let zipCode: String?
    let hvacType: String?
    let roofMaterial: String?
    let hasFireplace: Bool
    let hasPool: Bool
    let hasBasement: Bool
    let waterHeaterAge: Int?
    let createdAt: Date
}

struct TaskResponse: Decodable {
    let id: Int
    let houseId: Int
    let name: String
    let frequency: String
    let season: String?
    let dueDate: Date?
    let lastCompleted: Date?
    let nextDue: Date?
    let source: String
    let reason: String?
    let isDismissed: Bool
    let updatedAt: Date
    let createdAt: Date
}

struct CompletionResponse: Decodable {
    let id: Int
    let taskId: Int
    let completedAt: Date
    let notes: String?
}
