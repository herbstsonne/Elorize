import SwiftUI

struct FilterView: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  @State private var editMode: EditMode = .inactive
  @State private var showingDeleteSubjectsAlert = false
  
  var body: some View {
    ZStack {
      BackgroundColorView()
      VStack {
        if viewModel.subjects.isEmpty {
          showContentUnavailableView()
        } else {
          if editMode.isEditing {
						showEditableSubjectListView()
          } else {
            Form {
              showPickerFilterByKnowledge()
              showPickerSubject()
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
          }
        }
        Spacer()
      }
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					EditButton()
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(role: .destructive) {
						showingDeleteSubjectsAlert = true
					} label: {
						Label("Delete Selected", systemImage: "trash")
					}
					.disabled(viewModel.selectedSubjectIDs.isEmpty)
				}
			}
    }
    .environment(\.editMode, $editMode)
    .alert(
      "Confirm Deletion",
      isPresented: $showingDeleteSubjectsAlert
    ) {
      Button("Delete", role: .destructive) {
        viewModel.deleteSelectedSubjects()
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("This will delete all related cards. Do you want to proceed?")
    }
  }
}

private extension FilterView {
	
	@ViewBuilder
	func showPickerFilterByKnowledge() -> some View {
		Picker("FilterByKnowledge", selection: $viewModel.reviewFilter) {
			ForEach(ReviewFilter.allCases) { f in
				Text(f.rawValue)
					.tag(f)
					.accentText()
			}
		}
		.pickerStyle(.segmented)
		.tint(Color.app(.accent_default))
	}
	
  @ViewBuilder
  func showPickerSubject() -> some View {
    Picker("Subject", selection: $viewModel.selectedSubjectID) {
      Text("All")
        .tag(UUID?.none)
        .accentText()
      ForEach(viewModel.subjects) { subject in
        Text(subject.name)
          .tag(Optional(subject.id))
          .accentText()
      }
    }
		.labelsHidden()
    .pickerStyle(.inline)
  }
	
	@ViewBuilder
	func showContentUnavailableView() -> some View {
		ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
			.padding()
	}
	
	@ViewBuilder
	func showEditableSubjectListView() -> some View {
		List(selection: $viewModel.selectedSubjectIDs) {
			Section {
				showPickerFilterByKnowledge()
			}
			Section {
				ForEach(viewModel.subjects) { subject in
					Text(subject.name)
						.accentText()
						.contentShape(Rectangle())
				}
			}
		}
		.scrollContentBackground(.hidden)
		.listStyle(.insetGrouped)
	}
}

