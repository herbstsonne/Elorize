import Foundation
import SwiftData

@Model
public final class SubjectEntity {
	@Attribute(.unique) public var id: UUID
	public var name: String
	
	// Relationship to cards
	@Relationship(deleteRule: .cascade, inverse: \FlashCardEntity.subject)
	public var cards: [FlashCardEntity]
	
	public init(id: UUID = UUID(), name: String, cards: [FlashCardEntity] = []) {
		self.id = id
		self.name = name
		self.cards = cards
	}
}
