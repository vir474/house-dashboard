import Foundation
import SwiftData

@Model
final class HouseModel {
    @Attribute(.unique) var id: Int?
    var name: String
    var yearBuilt: Int?
    var zipCode: String?
    var hvacType: String?
    var roofMaterial: String?
    var hasFireplace: Bool
    var hasPool: Bool
    var hasBasement: Bool
    var waterHeaterAge: Int?
    var createdAt: Date
    var needsSync: Bool

    @Relationship(deleteRule: .cascade) var tasks: [TaskModel]

    init(
        name: String,
        yearBuilt: Int? = nil,
        zipCode: String? = nil,
        hvacType: String? = nil,
        roofMaterial: String? = nil,
        hasFireplace: Bool = false,
        hasPool: Bool = false,
        hasBasement: Bool = false,
        waterHeaterAge: Int? = nil
    ) {
        self.name = name
        self.yearBuilt = yearBuilt
        self.zipCode = zipCode
        self.hvacType = hvacType
        self.roofMaterial = roofMaterial
        self.hasFireplace = hasFireplace
        self.hasPool = hasPool
        self.hasBasement = hasBasement
        self.waterHeaterAge = waterHeaterAge
        self.createdAt = Date()
        self.needsSync = true
        self.tasks = []
    }
}
