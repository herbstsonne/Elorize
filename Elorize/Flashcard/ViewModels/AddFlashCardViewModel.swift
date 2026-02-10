import Foundation
internal import Combine

@MainActor
final class AddFlashCardViewModel: ObservableObject {

	@Published var front: String = ""
	@Published var back: String = ""
	@Published var selectedSubjectID: UUID?
	@Published var tagsText: String = ""
	@Published var isSaving = false
	@Published var errorMessage: String?

	private var repository: FlashCardRepository?
	
	func setRepository(_ repository: FlashCardRepository) {
		self.repository = repository
	}

	func save(with subjects: [SubjectEntity]) -> Bool {
		let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
		let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else {
				errorMessage = "Front and Back are required."
				return false
		}

		let subject = selectedSubjectID.flatMap { id in subjects.first { $0.id == id } }
		let tags = tagsText
				.split(separator: ",")
				.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
				.filter { !$0.isEmpty }

		let card = FlashCard(front: trimmedFront, back: trimmedBack, tags: tags)
		let entity = FlashCardEntity(from: card, subject: subject)

		isSaving = true
		defer { isSaving = false }

		do {
			try repository?.insert(entity)
			// Reset inputs on success
			front = ""
			back = ""
			tagsText = ""
			selectedSubjectID = nil
			return true
		} catch {
				errorMessage = "Failed to save card."
				return false
		}
	}
}
