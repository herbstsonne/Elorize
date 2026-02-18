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

public extension SubjectEntity {
  /// Case-insensitive search across front, back, and tags.
  /// Returns all cards if the query is empty/whitespace.
  func searchCards(matching query: String) -> [FlashCardEntity] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return flashCardsArray
    }
    let lower = trimmed.lowercased()
    return flashCardsArray.filter { card in
      if card.front.lowercased().contains(lower) { return true }
      if card.back.lowercased().contains(lower) { return true }
      if card.tags.contains(where: { $0.lowercased().contains(lower) }) { return true }
      return false
    }
  }

  /// All cards sorted by creation date descending.
  var allCardsSortedByDateDesc: [FlashCardEntity] {
    flashCardsArray.sorted { $0.createdAt > $1.createdAt }
  }
}

