import Foundation
import SwiftData

@Model
public final class FlowerEntity {
    public var id: UUID
    var flowerTypeRaw: String
    var grownAt: Date
    var studyDurationMinutes: Int
    
    var flowerType: FlowerType {
        get { FlowerType(rawValue: flowerTypeRaw) ?? .sunflower }
        set { flowerTypeRaw = newValue.rawValue }
    }
    
    init(flowerType: FlowerType, grownAt: Date = Date(), studyDurationMinutes: Int) {
        self.id = UUID()
        self.flowerTypeRaw = flowerType.rawValue
        self.grownAt = grownAt
        self.studyDurationMinutes = studyDurationMinutes
    }
}
