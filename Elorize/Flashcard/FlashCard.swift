import Foundation

/// A single flashcard with optional spaced-repetition metadata.
public struct FlashCard: Identifiable, Codable, Hashable {
    // MARK: - Identity
    public let id: UUID

    // MARK: - Content
    public var front: String
    public var back: String

    /// Optional tags to group or filter cards.
    public var tags: [String]

    // MARK: - Timestamps
    public var createdAt: Date
    public var lastReviewedAt: Date?

    // MARK: - Spaced repetition (simple SM-2 inspired fields)
    /// Ease factor (EF). Typical starting value around 2.5.
    public var easeFactor: Double

    /// Current interval in days until next review.
    public var intervalDays: Int

    /// How many times answered correctly in a row.
    public var consecutiveCorrect: Int

    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        front: String,
        back: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        easeFactor: Double = 2.5,
        intervalDays: Int = 0,
        consecutiveCorrect: Int = 0
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.tags = tags
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.easeFactor = max(1.3, easeFactor) // EF must not drop below ~1.3
        self.intervalDays = max(0, intervalDays)
        self.consecutiveCorrect = max(0, consecutiveCorrect)
    }

    // MARK: - Review Updates
    /// Update scheduling fields after a review.
    /// - Parameters:
    ///   - quality: 0-5 quality score (0 = complete blackout, 5 = perfect recall)
    ///   - reviewDate: The date of this review. Defaults to `Date()`.
    public mutating func registerReview(quality: Int, reviewDate: Date = Date()) {
        let q = max(0, min(5, quality))

        // Update ease factor (EF) per SM-2 variant
        // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        let delta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        easeFactor = max(1.3, easeFactor + delta)

        if q < 3 {
            // Reset on failure
            consecutiveCorrect = 0
            intervalDays = 0
        } else {
            consecutiveCorrect += 1
            switch consecutiveCorrect {
            case 1:
                intervalDays = 1
            case 2:
                intervalDays = 6
            default:
                // Next interval = previous * EF, rounded
                intervalDays = max(1, Int(round(Double(intervalDays) * easeFactor)))
            }
        }

        lastReviewedAt = reviewDate
    }

    /// The next due date, if calculable.
    public var nextDueDate: Date? {
        guard let last = lastReviewedAt else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: last)
    }
}

