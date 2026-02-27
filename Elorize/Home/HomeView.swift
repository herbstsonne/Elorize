import SwiftUI
import SwiftData

struct HomeView: View {

  @Environment(\.modelContext) private var context
  @EnvironmentObject var viewModel: HomeViewModel
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
  
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
  
  @State private var showingFilter = false
  
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
    .onAppear {
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
    }
    .onChange(of: viewModel.showingAddSubject) { oldValue, newValue in
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
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        XPProgressCompactView()
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showingFilter = true
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
              .font(.footnote)
            Text(viewModel.activeFilterSummary)
              .font(.footnote)
              .tint(Color.app(.accent_subtle))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
              .truncationMode(.tail)
          }
          .padding(.vertical, 6)
          .padding(.horizontal, 10)
          .contentShape(Rectangle())
        }
        .accessibilityLabel("Open filters. Active: \(viewModel.activeFilterSummary)")
      }
    }
    .sheet(isPresented: $showingFilter) {
      FilterView()
        .environmentObject(viewModel)
    }
    .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
      OnboardingView(
        isPresented: Binding(
          get: { !hasSeenOnboarding },
          set: { newValue in
            // newValue false -> dismiss
            hasSeenOnboarding = !newValue
          }
        ),
        onGetStarted: {
          hasSeenOnboarding = true
          // Navigate to Cards tab and open Add Subject
          viewModel.selectedTab = .cards // adapt to your tab type
          viewModel.showingAddSubject = true
        }
      )
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
            card: entity.card,
            actions: .init(
              onWrong: { viewModel.markWrong(entity) },
              onCorrect: { viewModel.markCorrect(entity) },
              onNext: { viewModel.advanceIndex() },
              onPrevious: { viewModel.previousIndex() }
            ),
            flashcardsRepository: FlashcardRepository(context: context)
          )
        )
      } else {
        ContentUnavailableView("No flashcards so far", systemImage: "rectangle.on.rectangle.slash", description: Text("Add cards in Cards tab."))
      }
    }
    .textViewStyle(16)
  }
}

#Preview {
  // In-memory container for preview
  let container = try! ModelContainer(
    for: SubjectEntity.self,
         FlashCardEntity.self,
    configurations: .init(isStoredInMemoryOnly: true)
  )

  // Seed data in a temporary context
  do {
    let tempContext = ModelContext(container)
    let subject = SubjectEntity(name: "Spanish")
    tempContext.insert(subject)
    let sample = FlashCard(front: "thank you", back: "gracias", tags: ["spanish"])
    tempContext.insert(FlashCardEntity(from: sample, subject: subject))
    try? tempContext.save()
  }

  // Provide required environment object
  return HomeView()
    .environmentObject(HomeViewModel())
    .modelContainer(container)
}

