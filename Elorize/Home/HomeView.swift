import SwiftUI
import SwiftData

struct HomeView: View {

  @StateObject var viewModel: HomeViewModel = HomeViewModel()
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
  @Environment(\.modelContext) private var context
  
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
          //viewModel.selectedTab = .cards // adapt to your tab type
          //viewModel.showingAddSubject = true
        }
      )
    }
    .onAppear {
      viewModel.attach(modelContext: context)
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
              onNext: { viewModel.advanceIndex() },
              onPrevious: { viewModel.previousIndex() }
            )
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

