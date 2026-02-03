import SwiftUI
import SwiftData

struct HomeView: View {

	@Environment(\.modelContext) private var context

	@StateObject private var viewModel = HomeViewModel(context: nil)

	@State private var showingDeleteAlert = false
	@State private var entityPendingDeletion: FlashCardEntity? = nil

	@Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
	private var flashCardEntities: [FlashCardEntity]

	@Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
	private var subjects: [SubjectEntity]
	
	init() {
		defineSegmentedPickerTextColors()
	}

	var body: some View {
		NavigationStack {
			ZStack {
				BackgroundColorView()
				VStack {
					showPickerToFilterCards()
					showFlashCardSection()
				}
			}
			.toolbar {
				leadingToolbarItems()
				trailingToolbarItems()
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
			.onChange(of: viewModel.showingAddSheet) { oldValue, newValue in
				if oldValue == true && newValue == false {
					// Sheet was dismissed — re-sync from live @Query results
					viewModel.flashCardEntities = flashCardEntities
					viewModel.subjects = subjects
				}
			}
		}
	}
}

// MARK: Define background

private extension HomeView {
	
	struct BackgroundColorView: View {
		
		var body: some View {
			ZStack {
				// Deep, inky background with a subtle vignette
				LinearGradient(
					colors: [Color.app(.background_primary), Color.app(.background_secondary)],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.ignoresSafeArea()
				
				// Soft vignette glow
				RadialGradient(
					colors: [Color.app(.accent_default).opacity(0.1), .clear],
					center: .center,
					startRadius: 10,
					endRadius: 380
				)
				.blendMode(.softLight)
				.ignoresSafeArea()
			}
		}
	}
}

// MARK: Define appearance

private extension HomeView {
	
	func defineSegmentedPickerTextColors() {
		UISegmentedControl.appearance().setTitleTextAttributes(
			[.foregroundColor: UIColor.app(.accent_default)],
			for: .normal
		)
		
		UISegmentedControl.appearance().setTitleTextAttributes(
			[.foregroundColor: UIColor.app(.accent_pressed)],
			for: .selected
		)
	}
}

// MARK: Extract parts of HomeView like Picker section, Flashcard section and Toolbar

private extension HomeView {

	@ViewBuilder
	func showPickerToFilterCards() -> some View {
		VStack {
			if subjects.isEmpty {
				ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
			} else {
				Picker("Subject", selection: $viewModel.selectedSubjectID) {
					Text("All")
						.tag(UUID?.none)
						.accentText()
					ForEach(subjects) { subject in
						Text(subject.name)
							.tag(Optional(subject.id))
							.accentText()
					}
				}
				.pickerStyle(.inline)
			}
			Picker("FilterByKnowledge", selection: $viewModel.reviewFilter) {
				ForEach(ReviewFilter.allCases) { f in
					Text(f.rawValue)
						.tag(f)
						.accentText()
				}
			}
			.pickerStyle(.segmented)
		}
	}

	@ViewBuilder
	func showFlashCardSection() -> some View {
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
				.centeredCardFrame()
			} else {
				ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
			}
		}
		.textViewStyle(16)
		.alert("Do you really want to delete this flash card?", isPresented: $showingDeleteAlert, presenting: entityPendingDeletion) { pending in
			Button("Delete", role: .destructive) {
				viewModel.delete(pending)
				entityPendingDeletion = nil
			}
			Button("Cancel", role: .cancel) {
				entityPendingDeletion = nil
			}
		} message: { _ in
			Text("This action cannot be undone.")
		}
	}

	@ToolbarContentBuilder
	func leadingToolbarItems() -> some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				viewModel.showingAddSubject = true
			} label: {
				Image(systemName: "folder.badge.plus")
			}
			.accessibilityLabel("Add subject")
		}
	}
	
	@ToolbarContentBuilder
	func trailingToolbarItems() -> some ToolbarContent {
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
