import Foundation
internal import Combine

@MainActor
final class AddSubjectViewModel: ObservableObject {

	@Published var name: String = ""
	@Published var isSaving = false
	@Published var errorMessage: String?
	
	private var repository: SubjectRepository?

	func setRepository(_ repository: SubjectRepository) {
		self.repository = repository
	}

	func save() -> Bool {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else {
			errorMessage = "Please enter a subject name."
			return false
		}

		isSaving = true
		defer { isSaving = false }

		let subject = SubjectEntity(name: trimmed)
		do {
			try repository?.insert(subject)
			name = ""
			return true
		} catch {
			errorMessage = "Failed to save subject."
			return false
		}
	}
}
