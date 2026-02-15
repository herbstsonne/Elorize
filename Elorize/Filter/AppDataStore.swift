import SwiftUI
internal import Combine

#if !canImport(SubjectModule)
public struct Subject: Identifiable, Equatable {
    public let id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
#endif

#if !canImport(FlashcardModule)
public struct Flashcard: Identifiable, Equatable {
    public let id: UUID
    public var subjectID: UUID
    public var front: String
    public var back: String

    public init(id: UUID = UUID(), subjectID: UUID, front: String, back: String) {
        self.id = id
        self.subjectID = subjectID
        self.front = front
        self.back = back
    }
}
#endif

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var subjects: [Subject] = []
    @Published var flashcards: [Flashcard] = []

    init() {}

    func deleteSubject(id: UUID) {
        subjects.removeAll { $0.id == id }
        flashcards.removeAll { $0.subjectID == id }
    }

    func upsertSubject(_ subject: Subject) {
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index] = subject
        } else {
            subjects.append(subject)
        }
    }

    func upsertFlashcard(_ card: Flashcard) {
        if let index = flashcards.firstIndex(where: { $0.id == card.id }) {
            flashcards[index] = card
        } else {
            flashcards.append(card)
        }
    }
}
