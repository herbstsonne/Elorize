import SwiftUI
import SwiftData
internal import Combine

final class CardsViewModel: ObservableObject {
    @Published var flashcards: [Flashcard] = []
    @Published var subjects: [Subject] = []
    
    // UI State expected by views
    @Published var showingAddSubject: Bool = false
    @Published var showingAddSheet: Bool = false
    
    // MARK: - Publishers to inform other view models
    private let subjectDidChangeSubject = PassthroughSubject<[Subject], Never>()
    private let flashcardDidChangeSubject = PassthroughSubject<[Flashcard], Never>()
    
    var subjectDidChange: AnyPublisher<[Subject], Never> { subjectDidChangeSubject.eraseToAnyPublisher() }
    var flashcardDidChange: AnyPublisher<[Flashcard], Never> { flashcardDidChangeSubject.eraseToAnyPublisher() }
    
    // Optional repositories if available
    private var flashcardsRepository: FlashcardRepository?
    private var subjectRepository: SubjectRepository?
    
    private var cancellables = Set<AnyCancellable>()
    private let store: AppDataStore
    
    init(store: AppDataStore = .shared) {
        self.store = store
        store.$flashcards
            .receive(on: DispatchQueue.main)
            .assign(to: &$flashcards)
        
        store.$subjects
            .receive(on: DispatchQueue.main)
            .assign(to: &$subjects)
        
        $subjects
            .dropFirst()
            .sink { [weak self] newSubjects in
                self?.subjectDidChangeSubject.send(newSubjects)
            }
            .store(in: &cancellables)
        
        $flashcards
            .dropFirst()
            .sink { [weak self] newCards in
                self?.flashcardDidChangeSubject.send(newCards)
            }
            .store(in: &cancellables)
    }
    
    func setRepositories(flashcardsRepository: FlashcardRepository?, subjectRepository: SubjectRepository?) {
        self.flashcardsRepository = flashcardsRepository
        self.subjectRepository = subjectRepository
    }
    
    // MARK: - Actions expected by CardsOverviewView
    func commitSubjectEdit(_ subject: SubjectEntity, newName: String) {
        // Prefer repository if provided
        if let repo = flashcardsRepository {
            repo.commitSubjectEdit(subject, newName: newName)
            subjectDidChangeSubject.send(self.subjects)
            return
        }
        // Fallback: update directly on the entity and try to save via its context
        subject.name = newName
        subject.modelContext?.saveOrIgnore()
        subjectDidChangeSubject.send(self.subjects)
    }
    
    func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) {
        if let repo = flashcardsRepository {
            repo.deleteCards(at: offsets, in: cards)
            flashcardDidChangeSubject.send(self.flashcards)
            return
        }
        // Fallback: delete directly from context
        let toDelete = offsets.map { cards[$0] }
        guard let context = toDelete.first?.modelContext else { return }
        toDelete.forEach { context.delete($0) }
        try? context.save()
        flashcardDidChangeSubject.send(self.flashcards)
    }
    
    func deleteSubjects(at offsets: IndexSet, subjects: [SubjectEntity]) {
        if let repo = flashcardsRepository {
            repo.deleteSubjects(at: offsets, subjects: subjects)
            subjectDidChangeSubject.send(self.subjects)
            return
        }
        let toDelete = offsets.map { subjects[$0] }
        guard let context = toDelete.first?.modelContext else { return }
        toDelete.forEach { context.delete($0) }
        try? context.save()
        subjectDidChangeSubject.send(self.subjects)
    }
    
    // Convenience save passthrough
    func save() {
        flashcardsRepository?.save()
    }
}
fileprivate extension ModelContext {
    func saveOrIgnore() {
        do { try save() } catch { /* ignore for now */ }
    }
}

