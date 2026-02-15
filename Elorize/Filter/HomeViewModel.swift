import SwiftUI
internal import Combine

final class HomeViewModel: ObservableObject {

  @Published var subjects: [Subject] = []
  @Published var flashcards: [Flashcard] = []
  @Published var currentIndex = 0
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var selectedSubjectID: UUID?
  @Published var reviewFilter: ReviewFilter = .all

  private var cancellables = Set<AnyCancellable>()
  private let store: AppDataStore
  private let generator: FlashcardGenerator
  private let reviewer: Reviewer
  
  private var flashcardsRepository: FlashcardRepository?
  private var exerciseRepository: ExerciseRepository?

  var filteredFlashCardEntities: [FlashCardEntity] {
    if let id = selectedSubjectID, let subject = subjects.first(where: { $0.id == id }) {
      return flashCardEntities.filter { $0.subject?.id == subject.id }
    } else {
      return flashCardEntities
    }
  }
  
  var filteredByOutcome: [FlashCardEntity] {
    switch reviewFilter {
    case .all:
      return filteredFlashCardEntities
    case .wrong:
      return filteredFlashCardEntities.filter { ($0.lastQuality ?? 0) <= 2 }
    case .correct:
      return filteredFlashCardEntities.filter { ($0.lastQuality ?? 0) >= 3 }
    }
  }

  convenience init(store: AppDataStore = .shared) {
      self.init(store: store,
                generator: FlashcardGenerator(),
                reviewer: Reviewer(),
                flashcardsRepository: nil,
                exerciseRepository: nil)
  }

  init(store: AppDataStore,
       generator: FlashcardGenerator,
       reviewer: Reviewer,
       flashcardsRepository: FlashcardRepository?,
       exerciseRepository: ExerciseRepository?) {
      self.store = store
      self.generator = generator
      self.reviewer = reviewer
      self.flashcardsRepository = flashcardsRepository
      self.exerciseRepository = exerciseRepository
      
      // Now that all stored properties are initialized, set up bindings
      setupBindings()
  }

  private func setupBindings() {
      store.$subjects
          .receive(on: DispatchQueue.main)
          .assign(to: &$subjects)
      
      store.$flashcards
          .receive(on: DispatchQueue.main)
          .assign(to: &$flashcards)
  }
  
  func nextEntity() -> FlashCardEntity? {
    generator.nextCardEntity(filteredByOutcome, index: currentIndex)
  }
  
  func save() {
    flashcardsRepository?.save()
  }
  
  func markWrong(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 2)
    exerciseRepository?.saveWrongAnswered(entity)
  }
  
  func markCorrect(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 5)
    exerciseRepository?.saveCorrectAnswered(entity)
  }
  
  func advanceIndex() {
    currentIndex = (currentIndex + 1) % max(1, filteredByOutcome.count)
  }
    
  func previousIndex() {
    currentIndex = (currentIndex - 1) % max(1, filteredByOutcome.count)
  }
}
