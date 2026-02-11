import SwiftUI
import SwiftData

struct HomeView: View {

  @EnvironmentObject var viewModel: HomeViewModel
  
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
  
  init() {
    defineSegmentedPickerTextColors()
  }
  
  var body: some View {
    ZStack {
      BackgroundColorView()
      VStack {
        showFlashCardSection()
      }
    }
    .toolbar {
      leadingToolbarItems()
      trailingToolbarItems()
    }
    .onAppear {
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
    }
    .sheet(isPresented: $viewModel.showingAddSubject) {
      AddSubjectView()
    }
    .sheet(isPresented: $viewModel.showingAddSheet) {
      AddFlashCardView(subjects: subjects)
    }
    .onChange(of: viewModel.showingAddSubject) { oldValue, newValue in
      if oldValue == true && newValue == false {
        viewModel.flashCardEntities = flashCardEntities
        viewModel.subjects = subjects
      }
    }
    .onChange(of: viewModel.showingAddSheet) { oldValue, newValue in
      if oldValue == true && newValue == false {
        viewModel.flashCardEntities = flashCardEntities
        viewModel.subjects = subjects
      }
    }
    .onChange(of: viewModel.reviewFilter) { _, _ in
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
    }
    .onChange(of: viewModel.selectedSubjectID) { _, _ in
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
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
  func showFlashCardSection() -> some View {
    Group {
      if let entity = viewModel.nextEntity() {
        FlashCardView(
          viewModel: FlashCardViewModel(
            card: entity.value,
            actions: .init(
              onWrong: { viewModel.markWrong(entity) },
              onCorrect: { viewModel.markCorrect(entity) },
              onNext: { viewModel.advanceIndex() }
            )
          )
        )
        .contextMenu {
          Button(role: .destructive) {
            viewModel.entityPendingDeletion = entity
            viewModel.showingDeleteAlert = true
          } label: {
            Label("Delete", systemImage: "trash")
          }
        }
      } else {
        ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
      }
    }
    .textViewStyle(16)
    .alert(
      "Do you really want to delete the current flash card?",
      isPresented: $viewModel.showingDeleteAlert,
      presenting: viewModel.entityPendingDeletion
    ) { pending in
      Button("Delete", role: .destructive) {
        viewModel.delete(pending)
        viewModel.entityPendingDeletion = nil
      }
      Button("Cancel", role: .cancel) {
        viewModel.entityPendingDeletion = nil
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
      .accessibilityLabel("Add subject/category")
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
          viewModel.entityPendingDeletion = entity
          viewModel.showingDeleteAlert = true
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

