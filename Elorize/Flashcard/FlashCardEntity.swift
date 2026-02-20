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

	// Tags as a simple array (SwiftData supports [String])
	public var tags: [String]

	// Timestamps
	public var createdAt: Date
	public var lastReviewedAt: Date?

	// Spaced repetition
	public var easeFactor: Double
	public var intervalDays: Int
	public var consecutiveCorrect: Int
	public var lastQuality: Int?
  
  public var correctCount: Int = 0
  public var wrongCount: Int = 0

	public init(
		id: UUID,
		front: String,
		back: String,
		tags: [String] = [],
		createdAt: Date = Date(),
		lastReviewedAt: Date? = nil,
		easeFactor: Double = 2.5,
		intervalDays: Int = 0,
		consecutiveCorrect: Int = 0,
		lastQuality: Int? = nil
	) {
		self.id = id
		self.front = front
		self.back = back
		self.tags = tags
		self.createdAt = createdAt
		self.lastReviewedAt = lastReviewedAt
		self.easeFactor = max(1.3, easeFactor)
		self.intervalDays = max(0, intervalDays)
		self.consecutiveCorrect = max(0, consecutiveCorrect)
		self.lastQuality = lastQuality
	}
}

// MARK: - Mapping to/from value type
public extension FlashCardEntity {
	// Note: We mirror the FlashCard's stable id onto the entity's id to keep a 1:1 mapping.
	convenience init(from card: FlashCard, subject: SubjectEntity?) {
		self.init(
			id: card.id,
			front: card.front,
			back: card.back,
			tags: card.tags,
			createdAt: card.createdAt,
			lastReviewedAt: card.lastReviewedAt,
			easeFactor: card.easeFactor,
			intervalDays: card.intervalDays,
			consecutiveCorrect: card.consecutiveCorrect,
			lastQuality: nil
		)
		self.subject = subject
	}

	var card: FlashCard {
		FlashCard(
			id: id,
			front: front,
			back: back,
			tags: tags,
			createdAt: createdAt,
			lastReviewedAt: lastReviewedAt,
			easeFactor: easeFactor,
			intervalDays: intervalDays,
			consecutiveCorrect: consecutiveCorrect
		)
	}
}

