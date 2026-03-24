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
  @State private var showingQuiz = false
  @State private var showingMultipleChoiceQuiz = false
  @State private var showingQuizSelection = false
  
  init() {
    defineSegmentedPickerTextColors()
  }
  
  var body: some View {
    ZStack {
      BackgroundColorView()
      VStack {
        showFlashCardSection()
      }
      
      // Celebration overlay in center of screen
      if viewModel.showLevelUpCelebration {
        Color.clear
          .ignoresSafeArea()
          .overlay(
            VStack(spacing: 16) {
              Text("🎉")
                .font(.system(size: 80))
            }
            .offset(y: -100)
            .scaleEffect(viewModel.celebrationScale)
            .opacity(viewModel.showLevelUpCelebration ? 1.0 : 0.0)
            .transition(.opacity)
          )
          .allowsHitTesting(false)
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
        HStack(spacing: 8) {
          // Shuffle button
          Button {
            if viewModel.isShuffled {
              viewModel.unshuffleCards()
            } else {
              viewModel.shuffleCards()
            }
          } label: {
            Image(systemName: viewModel.isShuffled ? "arrow.uturn.backward" : "shuffle")
              .font(.footnote)
              .foregroundStyle(viewModel.isShuffled ? Color.app(.accent_default) : Color.app(.accent_subtle))
              .padding(.leading, 12)
          }
          .accessibilityLabel(viewModel.isShuffled ? "Unshuffle cards" : "Shuffle cards")
          
          // Filter button
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
    }
    .sheet(isPresented: $showingFilter) {
      FilterView()
        .environmentObject(viewModel)
    }
    .sheet(isPresented: $showingQuizSelection) {
      QuizSelectionView(
        onNormalQuiz: {
          showingQuizSelection = false
          showingQuiz = true
        },
        onMultipleChoiceQuiz: {
          showingQuizSelection = false
          showingMultipleChoiceQuiz = true
        }
      )
      .presentationDetents([.height(300)])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showingQuiz) {
      QuizView(
        cards: viewModel.filteredByOutcome.map { entity in
          FlashCard(front: entity.front, back: entity.back)
        },
        sourceText: "Exercise Quiz",
        onQuizComplete: { score, total in
          viewModel.awardQuizXP(score: score, total: total)
        }
      )
    }
    .sheet(isPresented: $showingMultipleChoiceQuiz) {
      MultipleChoiceQuizView(
        cards: viewModel.filteredByOutcome.map { entity in
          FlashCard(front: entity.front, back: entity.back)
        },
        sourceText: "Exercise Quiz",
        onQuizComplete: { score, total in
          viewModel.awardQuizXP(score: score, total: total)
        }
      )
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
        VStack(spacing: 16) {
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
          
          // Quiz button
          Button {
            showingQuizSelection = true
          } label: {
            Label("Start Quiz", systemImage: "list.clipboard.fill")
              .font(.headline)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.app(.accent_default))
              .foregroundStyle(Color.app(.background_primary))
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .padding(.horizontal)
        }
      } else {
        ContentUnavailableView("No flashcards so far", systemImage: "rectangle.on.rectangle.slash", description: Text("Add cards in Cards tab."))
      }
    }
    .textViewStyle(16)
  }
}

// MARK: - Quiz Selection View

struct QuizSelectionView: View {
  @Environment(\.dismiss) private var dismiss
  let onNormalQuiz: () -> Void
  let onMultipleChoiceQuiz: () -> Void
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        VStack(spacing: 12) {
          Text("Choose Quiz Type")
            .font(.title2)
            .fontWeight(.bold)
        }
        .padding(.top)
        
        VStack(spacing: 16) {
          // Normal Quiz Button
          Button {
            onNormalQuiz()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                  Text("Quiz")
                    .font(.headline)
                }
                
                Text("Flip through flashcards and test yourself")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.leading)
              }
              
              Spacer()
              
              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.app(.background_secondary))
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .buttonStyle(.plain)
          
          // Multiple Choice Quiz Button
          Button {
            onMultipleChoiceQuiz()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Image(systemName: "list.bullet.circle.fill")
                    .font(.title2)
                  Text("Multiple Choice")
                    .font(.headline)
                }
                
                Text("Answer questions with multiple options")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.leading)
              }
              
              Spacer()
              
              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.app(.background_secondary))
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal)
        
        Spacer()
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .foregroundStyle(Color.app(.accent_default))
      .background(Color.app(.background_primary))
    }
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

