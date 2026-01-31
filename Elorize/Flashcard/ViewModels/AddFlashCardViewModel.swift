import Foundation
import SwiftData
internal import Combine

@MainActor
final class AddFlashCardViewModel: ObservableObject {
    private(set) var context: ModelContext?

    @Published var front: String = ""
    @Published var back: String = ""
    @Published var selectedSubjectID: UUID?
    @Published var tagsText: String = ""
    @Published var isSaving = false
    @Published var errorMessage: String?

    init(context: ModelContext? = nil) {
        self.context = context
    }

    func setContext(_ context: ModelContext) {
        self.context = context
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

        context?.insert(entity)
        do {
            try context?.save()
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
