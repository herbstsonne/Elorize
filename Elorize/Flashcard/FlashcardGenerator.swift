import Foundation

struct FlashcardGenerator {
	func nextCardEntity(_ entities: [FlashCardEntity], index: Int) -> FlashCardEntity? {
		guard !entities.isEmpty else { return nil }
		let safeIndex = max(0, min(index, entities.count - 1))
		return entities[safeIndex]
	}
}
