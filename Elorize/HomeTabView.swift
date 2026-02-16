import SwiftUI
import SwiftData
import UIKit

struct HomeTabView: View {
  
  @Environment(\.modelContext) private var context
  
  @ObservedObject private var viewModel = HomeViewModel()
  @State private var editMode: EditMode = .inactive
  
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]

  var body: some View {
    TabView(selection: $viewModel.currentTab) {
      NavigationStack {
        HomeView()
          .environmentObject(viewModel)
          .environment(\.editMode, $editMode)
      }
      .tag(AppTab.exercise)
      .tabItem {
        Label("Exercise", systemImage: "brain.head.profile")
      }
      
      NavigationStack {
        FilterView()
          .environmentObject(viewModel)
          .environment(\.editMode, $editMode)
      }
      .tag(AppTab.filter)
      .tabItem {
        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
      }
      
      NavigationStack {
        CardsOverviewView()
          .environmentObject(viewModel)
          .environment(\.editMode, $editMode)
      }
      .tag(AppTab.cards)
      .tabItem {
        Label("Cards", systemImage: "rectangle.on.rectangle.angled")
      }
    }
    .onChange(of: viewModel.currentTab) { _, _ in
      // Refresh local data when the tab changes and exit edit mode
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
      editMode = .inactive
    }
    .onChange(of: subjects) { _, newSubjects in
      // End edit mode when there are no subjects left and clear selection
      if newSubjects.isEmpty {
        editMode = .inactive
        viewModel.selectedSubjectIDs.removeAll()
      }
    }
    .tint(Color.app(.accent_subtle))
    .onAppear {
      viewModel.setRepository(
        SwiftDataExerciseRepository(context: context),
        SwiftDataSubjectRepository(context: context),
        FlashcardRepository(context: context)
      )
      viewModel.flashCardEntities = flashCardEntities
      viewModel.subjects = subjects
    }
  }
}

#Preview {
  let container = try! ModelContainer(for: SubjectEntity.self, FlashCardEntity.self, configurations: .init(isStoredInMemoryOnly: true))
  let context = ModelContext(container)
  
  let subject = SubjectEntity(name: "Spanish")
  context.insert(subject)
  let sample = FlashCard(front: "thank you", back: "gracias", tags: ["spanish"]) 
  context.insert(FlashCardEntity(from: sample, subject: subject))
  try? context.save()
  
  return HomeTabView()
    .modelContainer(container)
}

