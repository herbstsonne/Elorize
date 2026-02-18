import Foundation
import SwiftData
internal import Combine
import SwiftUI

enum HomeTab: Hashable {
  case home
  case filter
  case cards
}

@MainActor
final class HomeViewModel: ObservableObject {
  
  // Source data provided by the view via SwiftData @Query
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var subjects: [SubjectEntity] = []
  
  // UI State
  @Published var showingAddSubject = false
  @Published var showingAddSheet = false
  @Published var showingFilter = false
  @Published var currentIndex = 0
  @Published var selectedSubjectID: UUID?
  @Published var reviewFilter: ReviewFilter = .all
  @Published var showingDeleteAlert = false
  @Published var entityPendingDeletion: FlashCardEntity?
  @Published var selectedSubjectIDs: Set<UUID> = []
  @Published var selectedTab: HomeTab = .home {
    didSet { handleTabChange(selectedTab) }
  }
  
  func openFilter() { showingFilter = true }
  func closeFilter() { showingFilter = false }
  
  @AppStorage("app.currentTab") private var storedTabRaw: String = AppTab.exercise.rawValue
  @Published var currentTab: AppTab = .exercise {
    didSet { storedTabRaw = currentTab.rawValue }
  }
  
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
      // Include every card regardless of review outcome, including those never reviewed (nil)
      return filteredFlashCardEntities
    case .wrong:
      // Only include cards that have been explicitly reviewed with a low quality (<= 2)
      return filteredFlashCardEntities.filter { quality in
        if let q = quality.lastQuality { return q <= 2 }
        return false
      }
    case .correct:
      // Only include cards that have been explicitly reviewed with a high quality (>= 3)
      return filteredFlashCardEntities.filter { quality in
        if let q = quality.lastQuality { return q >= 3 }
        return false
      }
    }
  }

  init(
    generator: FlashcardGenerator = FlashcardGenerator(),
    reviewer: Reviewer = Reviewer()
  ) {
    // First assign stored properties to satisfy initialization rules
    self.generator = generator
    self.reviewer = reviewer

    // Now it's safe to read from @AppStorage via `self`
    if let stored = AppTab(rawValue: self.storedTabRaw) {
      self.currentTab = stored
    }
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
    entity.wrongCount += 1
    reviewer.registerReview(for: entity, quality: 2)
    exerciseRepository?.saveWrongAnswered(entity)
  }
  
  func markCorrect(_ entity: FlashCardEntity) {
    entity.correctCount += 1
    reviewer.registerReview(for: entity, quality: 5)
    exerciseRepository?.saveCorrectAnswered(entity)
  }
  
  func advanceIndex() {
    currentIndex = (currentIndex + 1) % max(1, filteredByOutcome.count)
  }
    
  func previousIndex() {
    let count = max(1, filteredByOutcome.count)
    currentIndex = (currentIndex - 1 + count) % count
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
  
  func refreshData(with flashCards: [FlashCardEntity], subjects: [SubjectEntity]) {
    self.flashCardEntities = flashCards
    self.subjects = subjects
  }
  
  @discardableResult
  func createSubject(named name: String) -> SubjectEntity? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    let subject = SubjectEntity(name: trimmed)
    do {
      try subjectRepository?.insert(subject)
    } catch {
      print("Couldn't insert subject: \(error)")
      return nil
    }
    // Keep local cache in sync for immediate UI updates
    subjects.append(subject)
    return subject
  }
  
  func saveFlashcard(front: String, back: String, tags: [String], subjectID: UUID?) -> Bool {
    let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else { return false }

    let subject: SubjectEntity? = {
      if let id = subjectID {
        return subjects.first(where: { $0.id == id })
      }
      return nil
    }()
    
    let flash = FlashCard(front: trimmedFront, back: trimmedBack, tags: tags)
    let entity = FlashCardEntity(from: flash, subject: subject)
    // Persist via repository if available
    flashcardsRepository?.saveNew(entity)
    flashcardsRepository?.save()

    // Update local cache for immediate UI reflection
    flashCardEntities.insert(entity, at: 0)
    return true
  }
  
  private func handleTabChange(_ tab: HomeTab) {
    switch tab {
    case .home:
      // Reset any Cards UI sheets when returning home
      showingAddSubject = false
      showingAddSheet = false
    case .filter:
      // Close transient UI when navigating to settings
      showingAddSubject = false
      showingAddSheet = false
    case .cards:
      // Prepare Cards state if needed; do not auto-open sheets here
      break
    }
  }
  
  func selectTab(_ tab: AppTab) {
    currentTab = tab
  }
}

