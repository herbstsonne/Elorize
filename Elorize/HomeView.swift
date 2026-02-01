import SwiftUI
import SwiftData

struct HomeView: View {

	@StateObject private var viewModel = HomeViewModel(context: nil)
	@Environment(\.modelContext) private var context
	@State private var showingDeleteAlert = false
	@State private var entityPendingDeletion: FlashCardEntity? = nil
	@Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
	private var flashCardEntities: [FlashCardEntity]

	@Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
	private var subjects: [SubjectEntity]

	private var filteredFlashCardEntities: [FlashCardEntity] {
		if let id = viewModel.selectedSubjectID, let subject = subjects.first(where: { $0.id == id }) {
			return flashCardEntities.filter { $0.subject?.id == subject.id }
		} else {
			return flashCardEntities // All subjects
		}
	}
    
	private var filteredByOutcome: [FlashCardEntity] {
		switch viewModel.reviewFilter {
		case .all:
			return filteredFlashCardEntities
		case .wrong:
			return filteredFlashCardEntities.filter { ($0.lastQuality ?? 0) <= 2 }
		case .correct:
			return filteredFlashCardEntities.filter { ($0.lastQuality ?? 0) >= 3 }
		}
	}

	private func delete(_ entity: FlashCardEntity) {
		context.delete(entity)
		do { try context.save() } catch { /* handle save error if needed */ }
		// Remove from local arrays used by the view model
		if let index = viewModel.flashCardEntities.firstIndex(where: { $0.id == entity.id }) {
			viewModel.flashCardEntities.remove(at: index)
		}
	}

	var body: some View {
		NavigationStack {
			VStack {
				HStack {
					Text("Subject/category:")
					Spacer()
					if subjects.isEmpty {
						ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
					} else {
						Picker("Subject", selection: $viewModel.selectedSubjectID) {
							Text("All").tag(UUID?.none)
							ForEach(subjects) { subject in
								Text(subject.name).tag(Optional(subject.id))
							}
						}
						.pickerStyle(.inline) // or .menu, depending on space
					}
				}
				Picker("FilterByKnowledge", selection: $viewModel.reviewFilter) {
					ForEach(ReviewFilter.allCases) { f in Text(f.rawValue).tag(f) }
				}
				.pickerStyle(.segmented)
				.padding(.horizontal)
				Spacer()
				Group {
					if let entity = viewModel.nextEntity() {
						FlashCardView(card: entity.value) {
							viewModel.markWrong(entity)
						} onCorrect: {
							viewModel.markCorrect(entity)
						} onNext: {
							viewModel.advanceIndex()
						}
						.contextMenu {
							Button(role: .destructive) {
								entityPendingDeletion = entity
								showingDeleteAlert = true
							} label: {
								Label("Delete", systemImage: "trash")
							}
						}
					} else {
						ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
					}
				}
			}
			.padding()
			.alert("Do you really want to delete this flash card?", isPresented: $showingDeleteAlert, presenting: entityPendingDeletion) { pending in
				Button("Delete", role: .destructive) {
					delete(pending)
					entityPendingDeletion = nil
				}
				Button("Cancel", role: .cancel) {
					entityPendingDeletion = nil
				}
			} message: { _ in
				Text("This action cannot be undone.")
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						viewModel.showingAddSubject = true
					} label: {
						Image(systemName: "folder.badge.plus")
					}
					.accessibilityLabel("Add subject")
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						viewModel.showingAddSheet = true
					} label: {
						Image(systemName: "plus")
					}
					.accessibilityLabel("Add sample card")
				}
				ToolbarItem(placement: .topBarTrailing) {
					if let entity = viewModel.nextEntity() {
						Button(role: .destructive) {
							entityPendingDeletion = entity
							showingDeleteAlert = true
						} label: {
							Image(systemName: "trash")
						}
						.accessibilityLabel("Delete current card")
					}
				}
			}
		}
		.onAppear {
			viewModel.setContext(context)
			viewModel.flashCardEntities = flashCardEntities
			viewModel.subjects = subjects
		}
		.sheet(isPresented: $viewModel.showingAddSubject) {
			AddSubjectView()
		}
		.sheet(isPresented: $viewModel.showingAddSheet) {
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

