import SwiftUI
import SwiftData

struct HomeView: View {

	@Environment(\.modelContext) private var context
	@Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
	private var entities: [FlashCardEntity]
	@State private var showingAddSheet = false
	
	@State private var generator: FlashcardGenerator?
	@State private var reviewer = Reviewer()

	var body: some View {
		NavigationStack {
			Group {
				if let entity = generator?.nextCardEntity(entities) {
					FlashCardView(card: entity.value) {
						reviewer.registerReview(for: entity, quality: 2)
						try? context.save()
					} onCorrect: {
						reviewer.registerReview(for: entity, quality: 5)
						try? context.save()
					}
				} else {
					ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
				}
			}
			.navigationTitle("Elorize")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button { showingAddSheet = true } label: { Image(systemName: "plus") }
							.accessibilityLabel("Add sample card")
				}
			}
		}
		.sheet(isPresented: $showingAddSheet) {
			AddFlashCardView()
		}
		.onAppear {
			generator = FlashcardGenerator()
		}
	}
}

#Preview {
    let container = try! ModelContainer(for: FlashCardEntity.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    // Seed one sample entity
    let sample = FlashCard(front: "thank you", back: "gracias", tags: ["spanish"]) 
    context.insert(FlashCardEntity(from: sample))
    try? context.save()

    return HomeView()
        .modelContainer(container)
}
