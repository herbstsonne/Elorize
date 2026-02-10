import Foundation
import SwiftData
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
  
  // Source data provided by the view via SwiftData @Query
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var subjects: [SubjectEntity] = []
  
  // UI State
  @Published var showingAddSubject = false
  @Published var showingAddSheet = false
  @Published var currentIndex = 0
  @Published var selectedSubjectID: UUID?
  @Published var reviewFilter: ReviewFilter = .all
	@Published var showingDeleteAlert = false
	@Published var entityPendingDeletion: FlashCardEntity?

	private var repository: FlashCardRepository?
	private let generator: FlashcardGenerator
	private let reviewer: Reviewer

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

  init(
		generator: FlashcardGenerator = FlashcardGenerator(),
		reviewer: Reviewer = Reviewer()
	) {
    self.generator = generator
    self.reviewer = reviewer
  }
  
	func setRepository(_ repository: FlashCardRepository) {
		self.repository = repository
	}
	
  func nextEntity() -> FlashCardEntity? {
    generator.nextCardEntity(filteredByOutcome, index: currentIndex)
  }
  
  func delete(_ entity: FlashCardEntity) {
		repository?.delete(entity)
    if let index = flashCardEntities.firstIndex(where: { $0.id == entity.id }) {
      flashCardEntities.remove(at: index)
    }
  }
  
  func markWrong(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 2)
		repository?.saveWrongAnswered(entity)
  }
  
  func markCorrect(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 5)
		repository?.saveCorrectAnswered(entity)
  }
  
  func advanceIndex() {
    currentIndex = (currentIndex + 1) % max(1, filteredByOutcome.count)
  }
}

