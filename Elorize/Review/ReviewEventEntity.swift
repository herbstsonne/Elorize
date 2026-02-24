import Foundation
import SwiftData

@Model
public final class ReviewEventEntity {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var isCorrect: Bool

    @Relationship public var card: FlashCardEntity?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        isCorrect: Bool,
        card: FlashCardEntity? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.isCorrect = isCorrect
        self.card = card
    }
}
