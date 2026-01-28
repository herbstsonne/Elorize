import Foundation

struct FlashcardGenerator {

	func nextCardEntity(_ entities: [FlashCardEntity], asOf date: Date = Date()) -> FlashCardEntity? {
		// Prefer due cards, otherwise any card
		if let due = entities.first(where: { entity in
			let card = entity.value
			guard let due = card.nextDueDate else { return true }
			return due <= date
		}) { return due }
		return entities.first
	}
}
