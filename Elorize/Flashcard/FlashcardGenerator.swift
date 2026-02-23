import Foundation

protocol FlashcardGeneratorProtocol {
  func nextCardEntity(_ cards: [FlashCardEntity], index: Int) -> FlashCardEntity?
}

struct FlashcardGenerator: FlashcardGeneratorProtocol {
	func nextCardEntity(_ entities: [FlashCardEntity], index: Int) -> FlashCardEntity? {
		guard !entities.isEmpty else { return nil }
		let safeIndex = max(0, min(index, entities.count - 1))
		return entities[safeIndex]
	}
}
