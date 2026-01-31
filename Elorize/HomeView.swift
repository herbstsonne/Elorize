import SwiftUI
import SwiftData

struct HomeView: View {

	@Environment(\.modelContext) private var context
	@Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
	private var flashCardEntities: [FlashCardEntity]
	@State private var showingAddSubject = false
	@State private var showingAddSheet = false
	@State private var currentIndex = 0
	
	@Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
	private var subjects: [SubjectEntity]
	
	@State private var selectedSubjectID: UUID?
	
	private var filteredFlashCardEntities: [FlashCardEntity] {
		if let id = selectedSubjectID, let subject = subjects.first(where: { $0.id == id }) {
			return flashCardEntities.filter { $0.subject?.id == subject.id }
		} else {
			return flashCardEntities // All subjects
		}
	}
	
	@State private var generator = FlashcardGenerator()
	@State private var reviewer = Reviewer()

	var body: some View {
		NavigationStack {
			VStack {
				if subjects.isEmpty {
					ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
				} else {
					Picker("Subject", selection: $selectedSubjectID) {
						Text("All").tag(UUID?.none)
						ForEach(subjects) { subject in
							Text(subject.name).tag(Optional(subject.id))
						}
					}
					.pickerStyle(.segmented) // or .menu, depending on space
					.padding(.horizontal)
				}
				Group {
					if let entity = generator.nextCardEntity(filteredFlashCardEntities, index: currentIndex) {
						FlashCardView(card: entity.value) {
							reviewer.registerReview(for: entity, quality: 2)
							try? context.save()
						} onCorrect: {
							reviewer.registerReview(for: entity, quality: 5)
							try? context.save()
						} onNext: {
							currentIndex = (currentIndex + 1) % max(1, filteredFlashCardEntities.count)
						}
					} else {
						ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
					}
				}
			}
			.navigationTitle("Elorize")
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						showingAddSubject = true
					} label: {
						Image(systemName: "folder.badge.plus")
					}
					.accessibilityLabel("Add subject")
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button { showingAddSheet = true } label: { Image(systemName: "plus") }
							.accessibilityLabel("Add sample card")
				}
			}
		}
		.sheet(isPresented: $showingAddSubject) {
			AddSubjectView()
		}
		.sheet(isPresented: $showingAddSheet) {
			AddFlashCardView(subjects: subjects)
		}
	}
}

#Preview {
    let container = try! ModelContainer(for: SubjectEntity.self, FlashCardEntity.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = ModelContext(container)

    // Seed one subject and one sample card
    let subject = SubjectEntity(name: "Spanish")
    context.insert(subject)
    let sample = FlashCard(front: "thank you", back: "gracias", tags: ["spanish"]) 
    context.insert(FlashCardEntity(from: sample, subject: subject))
    try? context.save()

    return HomeView()
        .modelContainer(container)
}

