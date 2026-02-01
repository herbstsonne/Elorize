import Foundation
import Testing
import SwiftData
@testable import Elorize

@MainActor
@Suite
struct HomeViewModelTests {
	
	// MARK: - Helper Types
	
	enum ReviewFilter {
		case all, wrong, correct
	}
	
	// MARK: - Properties
	
	var container: ModelContainer!
	var context: ModelContext!
	var viewModel: HomeViewModel!
	
	// MARK: - Setup
	
	mutating func setup() async {
		container = makeInMemoryContainer()
		context = container.mainContext
		viewModel = HomeViewModel(context: context)
		await seedData()
	}
	
	func makeInMemoryContainer() -> ModelContainer {
	    let config = ModelConfiguration(isStoredInMemoryOnly: true)
	    return try! ModelContainer(for: SubjectEntity.self, FlashCardEntity.self, configurations: config)
	}
	
	mutating func seedData() async {
		// Clear previous data if any
		let fetchSubjects = try! context.fetch(FetchDescriptor<SubjectEntity>())
		for subject in fetchSubjects {
			context.delete(subject)
		}
		let fetchCards = try! context.fetch(FetchDescriptor<FlashCardEntity>())
		for card in fetchCards {
			context.delete(card)
		}
		
		// Create Subjects
		let spanish = SubjectEntity(name: "Spanish")
		let french = SubjectEntity(name: "French")
		
		context.insert(spanish)
		context.insert(french)
		
		// Create Cards
		let card1 = FlashCardEntity(from: FlashCard.init(front: "Hello", back: "Hola"), subject: spanish)
		let card2 = FlashCardEntity(from: FlashCard.init(front: "Bye", back: "Adios"), subject: spanish)
		let card3 = FlashCardEntity(from: FlashCard.init(front: "Hello", back: "Salut"), subject: french)
		
		context.insert(card1)
		context.insert(card2)
		context.insert(card3)
		
		try! context.save()
		
		// Assign to viewModel
		await MainActor.run {
			viewModel.flashCardEntities = [card1, card2, card3]
			viewModel.subjects = [spanish, french]
		}
	}
	
	// MARK: - Tests
	
	@MainActor
	@Test("Filters by subject correctly")
	mutating func testFilterBySubject() async throws {
		await setup()
		
		#expect(viewModel.filteredFlashCardEntities.count == 3)
		
		let spanishSubject = viewModel.subjects.first { $0.name == "Spanish" }
		let spanishID = try #require(spanishSubject).id
		let frenchSubject = viewModel.subjects.first { $0.name == "French" }
		let frenchID = try #require(frenchSubject).id
		
		viewModel.selectedSubjectID = nil
		#expect(viewModel.filteredFlashCardEntities.count == 3)
		
		viewModel.selectedSubjectID = spanishID
		#expect(viewModel.filteredFlashCardEntities.count == 2)
		
		viewModel.selectedSubjectID = frenchID
		#expect(viewModel.filteredFlashCardEntities.count == 1)
	}
	
	@MainActor
	@Test("Filters by outcome correctly")
	mutating func testFilterByOutcome() async {
		await setup()
		
		viewModel.selectedSubjectID = nil
		
		viewModel.reviewFilter = .all
		#expect(viewModel.filteredFlashCardEntities.count == 3)
		
		viewModel.reviewFilter = .wrong
		let wrongCount = viewModel.filteredFlashCardEntities.filter { $0.lastQuality ?? 0 <= 2 }.count
		#expect(wrongCount > 0)
		#expect(wrongCount == viewModel.filteredFlashCardEntities.count)
		
		viewModel.reviewFilter = .correct
		let correctCount = viewModel.filteredFlashCardEntities.filter { $0.lastQuality ?? 0 >= 3 }.count
		#expect(correctCount > 0)
		#expect(correctCount == viewModel.filteredFlashCardEntities.count)
	}
	
	@MainActor
	@Test("nextEntity and advanceIndex traverse filtered list")
	mutating func testNextEntityAndAdvanceIndex() async throws {
		await setup()
		
		viewModel.selectedSubjectID = nil
		viewModel.reviewFilter = .all
		
		#expect(viewModel.filteredFlashCardEntities.count >= 2)
		
		viewModel.currentIndex = 0
		let firstEntity = viewModel.nextEntity()
		let firstID = try #require(firstEntity).id
		
		viewModel.advanceIndex()
		let secondEntity = viewModel.nextEntity()
		let secondID = try #require(secondEntity).id
		
		#expect(firstID != secondID)
		
		// advance past end to wrap around
		for _ in 0..<viewModel.filteredFlashCardEntities.count {
			viewModel.advanceIndex()
		}
		
		let wrappedEntity = viewModel.nextEntity()
		let wrappedID = try #require(wrappedEntity).id
		#expect(wrappedID == secondID || wrappedID == firstID)
	}
	
	@MainActor
	@Test("markCorrect and markWrong update lastQuality and save")
	mutating func testMarkCorrectAndMarkWrong() async throws {
		await setup()
		
		viewModel.selectedSubjectID = nil
		viewModel.reviewFilter = .all
		
		let first = viewModel.filteredFlashCardEntities.first
		let entity = try #require(first)
		
		// markCorrect
		viewModel.markCorrect(entity)
		#expect(entity.lastQuality == 5)
		
		// markWrong
		viewModel.markWrong(entity)
		#expect(entity.lastQuality == 2)
	}
}

