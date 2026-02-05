import SwiftUI
struct FilterView: View {

	let subjects: [SubjectEntity]
	@Binding var selectedSubjectID: UUID?
	@Binding var reviewFilter: ReviewFilter
	
	var body: some View {
	    NavigationStack {
	        ZStack {
	            BackgroundColorView()
	            VStack {
	                if subjects.isEmpty {
	                    ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
	                        .padding()
	                } else {
	                    Form {
	                        Picker("FilterByKnowledge", selection: $reviewFilter) {
	                            ForEach(ReviewFilter.allCases) { f in
	                                Text(f.rawValue)
	                                    .tag(f)
	                                    .accentText()
	                            }
	                        }
	                        .pickerStyle(.segmented)
	                        .tint(Color.app(.accent_default))

	                        Picker("Subject", selection: $selectedSubjectID) {
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
	                    .scrollContentBackground(.hidden)
	                    .listStyle(.plain)
	                }
	                Spacer()
	            }
	        }
	    }
	}
}

