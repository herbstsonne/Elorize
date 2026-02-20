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

  private var flashcardsRepository: FlashcardRepository?

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

  func setRepository(_ flashcardsRepository: FlashcardRepository?) {
    self.flashcardsRepository = flashcardsRepository
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
    var flash = FlashCard(front: front, back: back)
    let card = FlashCardEntity(from: flash, subject: nil)
    if let selectedID = selectedSubjectID,
       let subject = localSubjects.first(where: { $0.id == selectedID }) {
      card.subject = subject
    }
    // Insert and save
    flashcardsRepository?.saveNew(flashCard: card)
  }

  func createSubject() {
    let trimmed = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let subject = SubjectEntity(name: trimmed)
    flashcardsRepository?.saveNew(subject: subject)
    localSubjects.append(subject)
    selectedSubjectID = subject.id
    newSubjectName = ""
  }

    func save(subject: SubjectEntity? = nil) -> FlashCardEntity? {
        let trimmedFront = front.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let trimmedBack = back.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else {
            errorMessage = "Front and Back are required."
            return nil
        }

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

        flashcardsRepository?.saveNew(flashCard: entity)
        // Reset inputs on success
        front = ""
        back = ""
        tagsText = ""
        selectedSubjectID = subjects.first?.id
        return entity
    }
}

