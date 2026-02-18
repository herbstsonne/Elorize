import Foundation
import SwiftData

@Model
public final class SubjectEntity {

	@Attribute(.unique) public var id: UUID
	public var name: String
	
	// Relationship to cards
	@Relationship(deleteRule: .cascade, inverse: \FlashCardEntity.subject)
	public var cards: [FlashCardEntity]

  public var flashCardsArray: [FlashCardEntity] {
    // Attempt to expose a stable array regardless of underlying storage (Set or relationship)
    if let cards = self.cards as? Set<FlashCardEntity> {
      return Array(cards)
    } else if let cards = self.cards as? [FlashCardEntity] {
      return cards
    } else {
      return []
    }
  }
  
	public init(id: UUID = UUID(), name: String, cards: [FlashCardEntity] = []) {
		self.id = id
		self.name = name
		self.cards = cards
	}
}
