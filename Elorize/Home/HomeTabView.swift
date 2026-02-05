import SwiftUI
import SwiftData
import UIKit

struct HomeTabView: View {

    @Environment(\.modelContext) private var context

    @StateObject private var viewModel = HomeViewModel(context: nil)

    @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
    private var flashCardEntities: [FlashCardEntity]

    @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
    private var subjects: [SubjectEntity]

    var body: some View {
        TabView {
            HomeView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            FilterView(
                subjects: subjects,
                selectedSubjectID: $viewModel.selectedSubjectID,
                reviewFilter: $viewModel.reviewFilter
            )
            .tabItem {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        .tint(Color.app(.accent_subtle))
        .onAppear {
            viewModel.setContext(context)
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
