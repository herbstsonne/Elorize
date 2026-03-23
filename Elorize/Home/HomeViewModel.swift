import Foundation
import SwiftData
internal import Combine
import SwiftUI

enum HomeTab: Hashable {
  case home
  case cards
  case statistics
}

@MainActor
class HomeViewModel: ObservableObject {
  
  @Published var flashCardEntities: [FlashCardEntity] = []
  @Published var subjects: [SubjectEntity] = []
  @Published var showingAddSubject = false
  @Published var showingAddSheet = false
  @Published var showingFilter = false
  @Published var currentIndex = 0
  @Published var selectedSubjectID: UUID?
  @Published var reviewFilter: ReviewFilter = .all
  @Published var showingDeleteAlert = false
  @Published var entityPendingDeletion: FlashCardEntity?
  @Published var selectedSubjectIDs: Set<UUID> = []
  // Add FlashCard preselection
  @Published var preselectedSubjectForAdd: UUID?
  @Published var selectedTab: HomeTab = .home {
    didSet { handleTabChange(selectedTab) }
  }

  // CardsOverviewView
  @Published var editingSubjectID: PersistentIdentifier?
  @Published var editedSubjectName: String = ""
  @Published var highlightedCardID: UUID?

  @Published var expandedSubjectIDs: Set<PersistentIdentifier> = []
  @Published var searchText: String = ""
  @Published var subjectSort: SubjectSortCriterion = .name
  @Published var cardSort: CardSortCriterion = .front
  @Published var subjectSortDirection: SortDirection = .ascending
  @Published var cardSortDirection: SortDirection = .descending

  func openFilter() { showingFilter = true }
  func closeFilter() { showingFilter = false }
  
  @AppStorage("app.currentTab") private var storedTabRaw: String = AppTab.exercise.rawValue
  @AppStorage("gamification.totalXP") private var storedTotalXP: Int = 0
  @AppStorage("gamification.level") private var storedLevel: Int = 1
  
  @Published var currentTab: AppTab = .exercise {
    didSet { storedTabRaw = currentTab.rawValue }
  }
  
  private var flashcardsRepository: FlashcardRepositoryProtocol?
  private var subjectRepository: SubjectRepository?
  private var exerciseRepository: ExerciseRepository?
  private let generator: FlashcardGeneratorProtocol
  private let reviewer: ReviewerProtocol

  // MARK: - Gamification
  private var gamificationService: GamificationService!
  @Published var showLevelUpCelebration = false
  @Published var celebrationScale: CGFloat = 0.3
  private var lastObservedLevel: Int = 1
  private var isInitialLoad = true
  
  @Published var xpState: XPLevelState = XPLevelState(xp: 0, level: 1, xpForNextLevel: 100, xpIntoCurrentLevel: 0) {
    didSet {
      // Persist XP and Level whenever state updates
      storedTotalXP = xpState.xp
      storedLevel = xpState.level
      
      // Check for level up (but not on initial load)
      if xpState.level > lastObservedLevel && !isInitialLoad {
        showLevelUpCelebration = true
        celebrationScale = 0.3
        
        // Animate to large size over 2 seconds
        withAnimation(.spring(response: 1.5, dampingFraction: 0.6)) {
          celebrationScale = 2.0
        }
        
        // Auto-hide after the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
          withAnimation(.easeOut(duration: 0.4)) {
            self?.showLevelUpCelebration = false
          }
        }
      }
      lastObservedLevel = xpState.level
      isInitialLoad = false
    }
  }

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
      return filteredFlashCardEntities.filter { quality in
        if let q = quality.lastQuality { return q <= 2 }
        return false
      }
    case .correct:
      return filteredFlashCardEntities.filter { quality in
        if let q = quality.lastQuality { return q >= 3 }
        return false
      }
    }
  }
  
  var activeFilterSummary: String {
    var parts: [String] = []
    if let selectedID = selectedSubjectID,
       let subject = subjects.first(where: { $0.id == selectedID }) {
      parts.append(subject.name)
    }

    let label: String
    switch String(describing: reviewFilter).lowercased() {
    case let s where s.contains("wrong"):
      label = "Repeat"
    case let s where s.contains("correct"):
      label = "Got it!"
    default:
      label = String(describing: reviewFilter)
    }
    parts.append(label)

    if parts.isEmpty {
      return "All"
    } else {
      return parts.joined(separator: " • ")
    }
  }

  init(
    generator: FlashcardGeneratorProtocol = FlashcardGenerator(),
    reviewer: ReviewerProtocol = Reviewer()
  ) {
    self.generator = generator
    self.reviewer = reviewer
    if let stored = AppTab(rawValue: self.storedTabRaw) {
      self.currentTab = stored
    }
    // Restore XP and Level state from persisted storage
    self.gamificationService = GamificationService(initialXP: storedTotalXP, initialLevel: storedLevel)
    let restored = gamificationService.state
    self.xpState = restored
    self.lastObservedLevel = restored.level
  }
  
  func setRepository(_ exRepository: ExerciseRepository, _ subRepository: SubjectRepository, _ flashcardsRepository: FlashcardRepositoryProtocol?) {
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
    // Gamification: small XP for attempts
    xpState = gamificationService.addXP(1)
  }
  
  func markCorrect(_ entity: FlashCardEntity) {
    entity.correctCount += 1
    reviewer.registerReview(for: entity, quality: 5)
    exerciseRepository?.saveCorrectAnswered(entity)
    // Gamification: award XP for correct answers
    xpState = gamificationService.addXP(5)
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
    flashcardsRepository?.saveNew(flashCard: entity)
    flashCardEntities.insert(entity, at: 0)
    return true
  }
  
  /// Update an existing flashcard's content and subject, then persist.
  func updateCard(_ card: FlashCardEntity, front: String, back: String, tags: [String], subjectID: UUID?) {
    let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedFront.isEmpty, !trimmedBack.isEmpty else { return }

    // Update content
    card.front = trimmedFront
    card.back = trimmedBack
    card.tags = tags

    // Update subject relationship
    if let subjectID = subjectID, let newSubject = subjects.first(where: { $0.id == subjectID }) {
      card.subject = newSubject
    } else if subjectID == nil {
      card.subject = nil
    }

    // Persist changes
    flashcardsRepository?.save()
  }
  
  private func handleTabChange(_ tab: HomeTab) {
    switch tab {
    case .home:
      showingAddSubject = false
      showingAddSheet = false
    case .cards:
      break
    case .statistics:
      showingAddSubject = false
      showingAddSheet = false
    }
  }
  
  func selectTab(_ tab: AppTab) {
    currentTab = tab
  }
}

