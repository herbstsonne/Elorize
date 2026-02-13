import SwiftUI
import SwiftData
import UIKit

struct HomeTabView: View {
  
  @Environment(\.modelContext) private var context
  
	@StateObject private var viewModel = HomeViewModel()
  
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
	
	@State private var repository: SwiftDataFlashCardRepository?
  
  var body: some View {
		TabView {
			NavigationStack {
				HomeView()
					.environmentObject(viewModel)
			}
			.tabItem {
				Label("Home", systemImage: "house")
			}
			NavigationStack {
				FilterView()
					.environmentObject(viewModel)
			}
			.tabItem {
				Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
			}
      NavigationStack {
        CardsOverviewView()
          .environmentObject(viewModel)
      }
      .tabItem {
        Label("Cards", systemImage: "rectangle.on.rectangle.angled")
      }
		}
		.tint(Color.app(.accent_subtle))
		.onAppear {
			viewModel.setRepository(
				SwiftDataFlashCardRepository(context: context),
				SwiftDataSubjectRepository(context: context)
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
