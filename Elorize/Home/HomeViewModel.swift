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
  @Published var selectedSubjectIDs: Set<UUID> = []
  
  private var flashcardsRepository: FlashcardRepository?
  private var subjectRepository: SubjectRepository?
  private var exerciseRepository: ExerciseRepository?
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
  
  func setRepository(_ exRepository: ExerciseRepository, _ subRepository: SubjectRepository, _ flashcardsRepository: FlashcardRepository?) {
    self.exerciseRepository = exRepository
    self.subjectRepository = subRepository
    self.flashcardsRepository = flashcardsRepository
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
  
  func deleteSelectedSubjects() {
    let idsToDelete = selectedSubjectIDs
    guard !idsToDelete.isEmpty else { return }
    // Build a list of entities matching the selected IDs
    let toDelete = subjects.filter { idsToDelete.contains($0.id) }
    for subject in toDelete {
      subjectRepository?.delete(subject)
    }
    // Clear selection and update local subjects array by removing deleted items
    selectedSubjectIDs.removeAll()
    subjects.removeAll { idsToDelete.contains($0.id) }
    // Also clear subject filter if it points to a deleted subject
    if let current = selectedSubjectID, idsToDelete.contains(current) {
      selectedSubjectID = nil
    }
  }

  func commitSubjectEdit(_ subject: SubjectEntity, newName: String) {
    flashcardsRepository?.commitSubjectEdit(subject, newName: newName)
  }
  
  func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) {
    flashcardsRepository?.deleteCards(at: offsets, in: cards)
  }
  
  func deleteSubjects(at offsets: IndexSet, subjects: [SubjectEntity]) {
    flashcardsRepository?.deleteSubjects(at: offsets, subjects: subjects)
  }
}

