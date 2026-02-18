import Foundation
import SwiftUI
import SwiftData
internal import Combine

@MainActor
final class AddFlashCardViewModel: ObservableObject {

  // Inputs
  @Published var front: String = ""
  @Published var back: String = ""
  @Published var selectedSubjectID: UUID?
  @Published var tagsText: String = ""

  // UI state
  @Published var isSaving: Bool = false
  @Published var errorMessage: String?
  @Published var showingNewSubjectPrompt: Bool = false
  @Published var newSubjectName: String = ""
  @Published var localSubjects: [SubjectEntity] = []

    // Subjects used by the picker (mutable so newly created subjects appear immediately)
    @Published var subjects: [SubjectEntity] = []

    // SwiftData context
    private var context: ModelContext?

    func setContext(_ context: ModelContext) {
        self.context = context
    }

    func loadSubjects(_ initial: [SubjectEntity]) {
        self.subjects = initial
        if selectedSubjectID == nil {
            selectedSubjectID = subjects.first?.id
        }
    }

    func createSubject() {
        let name = newSubjectName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !name.isEmpty, let context else { return }
        let subject = SubjectEntity(name: name)
        context.insert(subject)
        do { try context.save() } catch {
            errorMessage = "Failed to save subject."
            return
        }
        subjects.append(subject)
        selectedSubjectID = subject.id
        newSubjectName = ""
    }

    private var tagsArray: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // Save a new flashcard using the SwiftData context directly
    func save(subject: SubjectEntity? = nil) -> FlashCardEntity? {
        let trimmedFront = front.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let trimmedBack = back.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else {
            errorMessage = "Front and Back are required."
            return nil
        }

        guard let context else { return nil }

        let subject: SubjectEntity? = {
            if let id = selectedSubjectID {
                return subjects.first(where: { $0.id == id })
            }
            return nil
        }()

        let flash = FlashCard(front: trimmedFront, back: trimmedBack, tags: tagsArray)
        let entity = FlashCardEntity(from: flash, subject: subject)

        isSaving = true
        defer { isSaving = false }

        do {
            context.insert(entity)
            try context.save()
            // Reset inputs on success
            front = ""
            back = ""
            tagsText = ""
            selectedSubjectID = subjects.first?.id
            return entity
        } catch {
            errorMessage = "Failed to save card."
            return nil
        }
    }
}

