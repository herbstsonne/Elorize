import Foundation
import SwiftData

@Model
public final class FlashCardEntity {
	// Identity
	@Attribute(.unique) public var id: UUID
	@Relationship var subject: SubjectEntity?

	// Content
	public var front: String
	public var back: String
	public var note: String?

	// Tags as a simple array (SwiftData supports [String])
	public var tags: [String]

	// Timestamps
	public var createdAt: Date
	public var lastReviewedAt: Date?

	// Spaced repetition
	public var easeFactor: Double
	public var intervalDays: Int
	public var consecutiveCorrect: Int

	public init(
		id: UUID = UUID(),
		front: String,
		back: String,
		note: String? = nil,
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
		self.note = note
		self.tags = tags
		self.createdAt = createdAt
		self.lastReviewedAt = lastReviewedAt
		self.easeFactor = max(1.3, easeFactor)
		self.intervalDays = max(0, intervalDays)
		self.consecutiveCorrect = max(0, consecutiveCorrect)
	}
}

// MARK: - Mapping to/from value type
public extension FlashCardEntity {
	convenience init(from card: FlashCard, subject: SubjectEntity?) {
		self.init(
			id: card.id,
			front: card.front,
			back: card.back,
			note: card.note,
			tags: card.tags,
			createdAt: card.createdAt,
			lastReviewedAt: card.lastReviewedAt,
			easeFactor: card.easeFactor,
			intervalDays: card.intervalDays,
			consecutiveCorrect: card.consecutiveCorrect
		)
		self.subject = subject
	}

	var value: FlashCard {
		FlashCard(
			id: id,
			front: front,
			back: back,
			note: note,
			tags: tags,
			createdAt: createdAt,
			lastReviewedAt: lastReviewedAt,
			easeFactor: easeFactor,
			intervalDays: intervalDays,
			consecutiveCorrect: consecutiveCorrect
		)
	}
}
