import SwiftUI
internal import Combine
import SwiftData

final class HomeViewModel: ObservableObject {

  @Published var subjects: [SubjectEntity] = []
  @Published var flashcards: [Flashcard] = []
  @Published var currentIndex = 0
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var selectedSubjectID: UUID?
  @Published var reviewFilter: ReviewFilter = .all

  private var cancellables = Set<AnyCancellable>()
  private let generator: FlashcardGenerator
  private let reviewer: Reviewer
  
  private var flashcardsRepository: FlashcardRepository?
  private var exerciseRepository: ExerciseRepository?
  private var cardsViewModel: CardsViewModel?

  private weak var modelContext: ModelContext?

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

  init(generator: FlashcardGenerator = FlashcardGenerator(),
       reviewer: Reviewer = Reviewer(),
       flashcardsRepository: FlashcardRepository? = nil,
       exerciseRepository: ExerciseRepository? = nil) {
      self.generator = generator
      self.reviewer = reviewer
      self.flashcardsRepository = flashcardsRepository
      self.exerciseRepository = exerciseRepository
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

  // MARK: - SwiftData attachment and fetching
  func attach(modelContext: ModelContext) {
    self.modelContext = modelContext
    refetchAll()
  }

  func refetchAll() {
    guard let context = modelContext else { return }
    let subjectsDescriptor = FetchDescriptor<SubjectEntity>(sortBy: [SortDescriptor(\.name, order: .forward)])
    let cardsDescriptor = FetchDescriptor<FlashCardEntity>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    do {
      subjects = try context.fetch(subjectsDescriptor)
      flashCardEntities = try context.fetch(cardsDescriptor)
    } catch {
      // You may want to surface this error to the UI or log it
      print("HomeViewModel refetchAll error: \(error)")
    }
  }
}
