import SwiftUI

struct FilterView: View {

	@EnvironmentObject var viewModel: HomeViewModel

	var subjects: [SubjectEntity] { viewModel.subjects }

    private var selectedSubjectIDBinding: Binding<UUID?> {
        Binding<UUID?>(
            get: { viewModel.selectedSubjectID },
            set: { viewModel.selectedSubjectID = $0 }
        )
    }

    private var reviewFilterBinding: Binding<ReviewFilter> {
        Binding<ReviewFilter>(
            get: { viewModel.reviewFilter },
            set: { viewModel.reviewFilter = $0 }
        )
    }

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
                            Picker("FilterByKnowledge", selection: reviewFilterBinding) {
                                ForEach(ReviewFilter.allCases) { f in
                                    Text(f.rawValue)
                                        .tag(f)
                                        .accentText()
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Color.app(.accent_default))

                            Picker("Subject", selection: selectedSubjectIDBinding) {
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

