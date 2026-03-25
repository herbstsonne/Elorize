import Foundation
import SwiftData

@Model
public final class ReviewEventEntity {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var isCorrect: Bool
    /// Quality score from 0-5 (0 = complete failure, 5 = perfect recall)
    /// Default is 0 to support migration from older versions
    public var quality: Int = 0

    @Relationship public var card: FlashCardEntity?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        isCorrect: Bool,
        quality: Int = 0,
        card: FlashCardEntity? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.isCorrect = isCorrect
        self.quality = quality
        self.card = card
    }
}
