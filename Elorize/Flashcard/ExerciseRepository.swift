import Foundation
import SwiftData

protocol ExerciseRepository {
	func saveWrongAnswered(_ entity: FlashCardEntity)
	func saveCorrectAnswered(_ entity: FlashCardEntity)
	func insert(_ entity: FlashCardEntity) throws
	func save()
}

final class SwiftDataExerciseRepository: ExerciseRepository {

	private let context: ModelContext

	init(context: ModelContext) {
		self.context = context
	}

	func saveWrongAnswered(_ entity: FlashCardEntity) {
		entity.lastQuality = 2
		save()
	}

	func saveCorrectAnswered(_ entity: FlashCardEntity) {
		entity.lastQuality = 5
		save()
	}

	func insert(_ entity: FlashCardEntity) throws {
		context.insert(entity)
		try context.save()
	}

	func save() {
		do {
			try context.save()
		} catch {
			// Handle save error appropriately (log, assertion, etc.)
			#if DEBUG
			print("SwiftDataFlashCardRepository save error: \(error)")
			#endif
		}
	}
}

