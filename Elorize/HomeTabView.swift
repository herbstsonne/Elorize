import SwiftUI
import SwiftData
import UIKit

struct HomeTabView: View {
  
  @Environment(\.modelContext) private var context
  
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
	
	@State private var repository: SwiftDataExerciseRepository?
  
  var body: some View {
		TabView {
			NavigationStack {
				HomeView()
			}
			.tabItem {
				Label("Exercise", systemImage: "brain.head.profile")
			}
			NavigationStack {
				FilterView()
			}
			.tabItem {
				Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
			}
      NavigationStack {
        CardsOverviewView()
      }
      .tabItem {
        Label("Cards", systemImage: "rectangle.on.rectangle.angled")
      }
		}
		.tint(Color.app(.accent_subtle))
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
