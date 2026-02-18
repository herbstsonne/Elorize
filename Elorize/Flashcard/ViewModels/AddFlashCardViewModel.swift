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

    private var tagsArray: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
  

  func insertFlashcard() {
    isSaving = true
    // Trim inputs
    let front = front.trimmingCharacters(in: .whitespacesAndNewlines)
    let back = back.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !front.isEmpty, !back.isEmpty else {
      isSaving = false
      return
    }
    let tags = tagsText
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    let card = FlashCardEntity(front: front, back: back, tags: tags)
    if let selectedID = selectedSubjectID,
       let subject = localSubjects.first(where: { $0.id == selectedID }) {
      card.subject = subject
    }
    // Insert and save
    context?.insert(card)  }

  func createSubject() {
    let trimmed = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let subject = SubjectEntity(name: trimmed)
    context?.insert(subject)
    do { try context?.save() } catch { /* handle save error if needed */ }
    // Update local subjects and selection
    localSubjects.append(subject)
    selectedSubjectID = subject.id
    newSubjectName = ""
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

