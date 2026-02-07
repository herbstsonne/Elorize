import Foundation
import SwiftData
internal import Combine

@MainActor
final class AddSubjectViewModel: ObservableObject {
	private(set) var context: ModelContext?

	@Published var name: String = ""
	@Published var isSaving = false
	@Published var errorMessage: String?

	init(context: ModelContext? = nil) {
			self.context = context
	}

	func setContext(_ context: ModelContext) {
			self.context = context
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
		context?.insert(subject)
		do {
			try context?.save()
			name = ""
			return true
		} catch {
			errorMessage = "Failed to save subject."
			return false
		}
	}
}
