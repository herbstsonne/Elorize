import Testing
@testable import Elorize
import SwiftUI
import Elorize

typealias FlashcardRepositoryProtocol = Elorize.FlashcardRepositoryProtocol
typealias SubjectRepositoryProtocol = Elorize.SubjectRepository
typealias ExerciseRepositoryProtocol = Elorize.ExerciseRepository
typealias ReviewerProtocol = Elorize.ReviewerProtocol
typealias FlashcardGeneratorProtocol = Elorize.FlashcardGeneratorProtocol

// MARK: - Fakes

@MainActor
final class FakeFlashcardRepository: FlashcardRepositoryProtocol {
    var savedNew: [FlashCardEntity] = []
    var committedSubjectEdits: [(SubjectEntity, String)] = []
    var deletedCardOffsets: IndexSet?
    var deletedCardSource: [FlashCardEntity]?
    var deletedSubjectOffsets: IndexSet?
    var deletedSubjectSource: [SubjectEntity]?

    func save() {}
    func saveNew(flashCard: FlashCardEntity) { savedNew.append(flashCard) }
    func commitSubjectEdit(_ subject: SubjectEntity, newName: String) { committedSubjectEdits.append((subject, newName)) }
    func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) { deletedCardOffsets = offsets; deletedCardSource = cards }
    func deleteSubjects(at offsets: IndexSet, subjects: [SubjectEntity]) { deletedSubjectOffsets = offsets; deletedSubjectSource = subjects }
}

@MainActor
final class FakeSubjectRepository: SubjectRepository {
  
  var saveCalled: Bool = false

  func save() {
    saveCalled = true
  }
  
  var inserted: [SubjectEntity] = []
  var deleted: [SubjectEntity] = []
  var shouldThrowOnInsert = false

  func insert(_ subject: SubjectEntity) throws {
      if shouldThrowOnInsert { throw NSError(domain: "FakeSubjectRepository", code: 1) }
      inserted.append(subject)
  }

  func delete(_ subject: SubjectEntity) {
    deleted.append(subject)
  }
}

@MainActor
final class FakeExerciseRepository: ExerciseRepository {

  var saveCalled: Bool = false
  var inserted: [Elorize.FlashCardEntity] = []

  func insert(_ entity: Elorize.FlashCardEntity) throws {
    inserted.append(entity)
  }
  
  func save() {
    saveCalled = true
  }
  
  var savedWrong: [FlashCardEntity] = []
  var savedCorrect: [FlashCardEntity] = []

  func saveWrongAnswered(_ entity: FlashCardEntity) { savedWrong.append(entity) }
  func saveCorrectAnswered(_ entity: FlashCardEntity) { savedCorrect.append(entity) }
}

@MainActor
final class FakeReviewer: ReviewerProtocol {
    var registered: [(FlashCardEntity, Int)] = []
    func registerReview(for entity: FlashCardEntity, quality: Int) {
        registered.append((entity, quality))
    }
}

@MainActor
final class FakeGenerator: FlashcardGeneratorProtocol {
    var lastRequestedIndex: Int?
    var lastRequestedCards: [FlashCardEntity] = []
    func nextCardEntity(_ cards: [FlashCardEntity], index: Int) -> FlashCardEntity? {
        lastRequestedIndex = index
        lastRequestedCards = cards
        return cards.isEmpty ? nil : cards[min(index, cards.count - 1)]
    }
}

// MARK: - Helpers to build entities

@MainActor
private func makeSubject(name: String = "Test") -> SubjectEntity {
    let s = SubjectEntity(name: name)
    s.id = UUID()
    return s
}

@MainActor
private func makeCard(front: String = "Q", back: String = "A", subject: SubjectEntity? = nil, lastQuality: Int? = nil) -> FlashCardEntity {
    let f = FlashCard(front: front, back: back, tags: [])
    let e = FlashCardEntity(from: f, subject: subject)
    if let q = lastQuality { e.lastQuality = q }
    return e
}

// MARK: - Tests

@Suite("HomeViewModel real behavior")
@MainActor
struct HomeViewModel_RealTests {

    @Test("createSubject trims and appends to subjects")
    func testCreateSubject() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let flashRepo = FakeFlashcardRepository()
        let subjectRepo = FakeSubjectRepository()
        let exerciseRepo = FakeExerciseRepository()
        vm.setRepository(exerciseRepo, subjectRepo, flashRepo)

        #expect(vm.subjects.isEmpty)
        let created = vm.createSubject(named: "  Algebra  ")
        #expect(created != nil)
        #expect(created?.name == "Algebra")
        #expect(vm.subjects.count == 1)
        #expect(subjectRepo.inserted.count == 1)
    }

    @Test("createSubject returns nil for empty name and doesn't mutate state")
    func testCreateSubjectEmpty() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let subjectRepo = FakeSubjectRepository()
        vm.setRepository(FakeExerciseRepository(), subjectRepo, FakeFlashcardRepository())

        let created = vm.createSubject(named: "   ")
        #expect(created == nil)
        #expect(vm.subjects.isEmpty)
        #expect(subjectRepo.inserted.isEmpty)
    }

    @Test("saveFlashcard validates inputs, associates subject, updates cache and repository")
    func testSaveFlashcard() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let flashRepo = FakeFlashcardRepository()
        let subjectRepo = FakeSubjectRepository()
        vm.setRepository(FakeExerciseRepository(), subjectRepo, flashRepo)

        let s = vm.createSubject(named: "Math")
        let ok = vm.saveFlashcard(front: "  2+2 ", back: " 4 ", tags: ["arithmetic"], subjectID: s?.id)
        #expect(ok)
        #expect(vm.flashCardEntities.count == 1)
        #expect(flashRepo.savedNew.count == 1)
        #expect(vm.flashCardEntities.first?.subject?.id == s?.id)
    }

    @Test("saveFlashcard rejects invalid inputs")
    func testSaveFlashcardRejects() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        vm.setRepository(FakeExerciseRepository(), FakeSubjectRepository(), FakeFlashcardRepository())

        #expect(!vm.saveFlashcard(front: "", back: "A", tags: [], subjectID: nil))
        #expect(!vm.saveFlashcard(front: "Q", back: " ", tags: [], subjectID: nil))
        #expect(vm.flashCardEntities.isEmpty)
    }

    @Test("filtering by outcome: .wrong returns lastQuality <= 2, .correct returns >= 3")
    func testFilteringByOutcome() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let s = makeSubject(name: "Any")
        let wrong = makeCard(subject: s, lastQuality: 2)
        let correct = makeCard(subject: s, lastQuality: 5)
        let never = makeCard(subject: s, lastQuality: nil)
        vm.refreshData(with: [wrong, correct, never], subjects: [s])

        vm.reviewFilter = .all
        #expect(vm.filteredByOutcome.count == 3)

        vm.reviewFilter = .wrong
        #expect(vm.filteredByOutcome.count == 1)
        #expect(vm.filteredByOutcome.first?.id == wrong.id)

        vm.reviewFilter = .correct
        #expect(vm.filteredByOutcome.count == 1)
        #expect(vm.filteredByOutcome.first?.id == correct.id)
    }

    @Test("activeFilterSummary maps wrong->Repeat and correct->Got it!")
    func testActiveFilterSummaryLabels() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let s = makeSubject(name: "Biology")
        vm.refreshData(with: [], subjects: [s])
        vm.selectedSubjectID = s.id

        vm.reviewFilter = .wrong
        #expect(vm.activeFilterSummary.contains("Biology"))
        #expect(vm.activeFilterSummary.contains("Repeat"))

        vm.reviewFilter = .correct
        #expect(vm.activeFilterSummary.contains("Got it!"))
    }

    @Test("advanceIndex and previousIndex wrap around filtered list")
    func testIndexWrapping() throws {
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        let cards = [makeCard(), makeCard(), makeCard()]
        vm.refreshData(with: cards, subjects: [])

        vm.reviewFilter = .all
        vm.currentIndex = 0
        vm.advanceIndex()
        #expect(vm.currentIndex == 1)
        vm.advanceIndex()
        #expect(vm.currentIndex == 2)
        vm.advanceIndex()
        #expect(vm.currentIndex == 0)

        vm.previousIndex()
        #expect(vm.currentIndex == 2)
    }

    @Test("markWrong and markCorrect increment counts and call reviewer/repositories")
    func testMarking() throws {
        let reviewer = FakeReviewer()
        let exercise = FakeExerciseRepository()
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        vm.setRepository(exercise, FakeSubjectRepository(), FakeFlashcardRepository())

        let card = makeCard()
        #expect(card.correctCount == 0 && card.wrongCount == 0)
        vm.markWrong(card)
        #expect(card.wrongCount == 1)
        #expect(reviewer.registered.last?.1 == 2)
        #expect(exercise.savedWrong.last?.id == card.id)

        vm.markCorrect(card)
        #expect(card.correctCount == 1)
        #expect(reviewer.registered.last?.1 == 5)
        #expect(exercise.savedCorrect.last?.id == card.id)
    }

    @Test("deleteSelectedSubjects removes from cache, clears selection, and calls repository")
    func testDeleteSelectedSubjects() throws {
        let subjectRepo = FakeSubjectRepository()
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        vm.setRepository(FakeExerciseRepository(), subjectRepo, FakeFlashcardRepository())

        let s1 = makeSubject(name: "One")
        let s2 = makeSubject(name: "Two")
        vm.refreshData(with: [], subjects: [s1, s2])
        vm.selectedSubjectIDs = [s1.id, s2.id]
        vm.selectedSubjectID = s1.id

        vm.deleteSelectedSubjects()

        #expect(vm.subjects.isEmpty)
        #expect(vm.selectedSubjectIDs.isEmpty)
        #expect(vm.selectedSubjectID == nil)
        #expect(subjectRepo.deleted.count == 2)
    }

    @Test("commitSubjectEdit delegates to flashcardsRepository")
    func testCommitSubjectEdit() throws {
        let flashRepo = FakeFlashcardRepository()
        let vm = HomeViewModel(generator: FakeGenerator(), reviewer: FakeReviewer())
        vm.setRepository(FakeExerciseRepository(), FakeSubjectRepository(), flashRepo)

        let subject = makeSubject(name: "Old")
        vm.commitSubjectEdit(subject, newName: "New")
        #expect(flashRepo.committedSubjectEdits.count == 1)
        #expect(flashRepo.committedSubjectEdits.first?.0.id == subject.id)
        #expect(flashRepo.committedSubjectEdits.first?.1 == "New")
    }
}

