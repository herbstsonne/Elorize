import Foundation
import SwiftData
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
  // Inputs (injected)
  private(set) var context: ModelContext?
  private let generator: FlashcardGenerator
  private let reviewer: Reviewer
  
  // Source data provided by the view via SwiftData @Query
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var subjects: [SubjectEntity] = []
  
  // UI State
  @Published var showingAddSubject = false
  @Published var showingAddSheet = false
  @Published var currentIndex = 0
  @Published var selectedSubjectID: UUID? = nil
  @Published var reviewFilter: ReviewFilter = .all
	@Published var showingDeleteAlert = false
	@Published var entityPendingDeletion: FlashCardEntity? = nil
  
  // Derived data
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
  
  init(context: ModelContext?, generator: FlashcardGenerator = FlashcardGenerator(), reviewer: Reviewer = Reviewer()) {
    self.context = context
    self.generator = generator
    self.reviewer = reviewer
  }
  
  func setContext(_ context: ModelContext) {
    self.context = context
  }
  
  func nextEntity() -> FlashCardEntity? {
    generator.nextCardEntity(filteredByOutcome, index: currentIndex)
  }
  
  func delete(_ entity: FlashCardEntity) {
    guard let context = context else { return }
    context.delete(entity)
    do { try context.save() } catch { /* handle save error if needed */ }
    // Remove from local arrays used by the view model
    if let index = flashCardEntities.firstIndex(where: { $0.id == entity.id }) {
      flashCardEntities.remove(at: index)
    }
  }
  
  func markWrong(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 2)
    entity.lastQuality = 2
    try? context?.save()
  }
  
  func markCorrect(_ entity: FlashCardEntity) {
    reviewer.registerReview(for: entity, quality: 5)
    entity.lastQuality = 5
    try? context?.save()
  }
  
  func advanceIndex() {
    currentIndex = (currentIndex + 1) % max(1, filteredByOutcome.count)
  }
}

