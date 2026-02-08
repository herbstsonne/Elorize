import SwiftUI

struct FilterView: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  
  var body: some View {
    ZStack {
      BackgroundColorView()
      VStack {
        if viewModel.subjects.isEmpty {
          showContentUnavailableView()
        } else {
          Form {
            showPickerFilterByKnowledge()
						showPickerSubject()
          }
          .scrollContentBackground(.hidden)
          .listStyle(.plain)
        }
        Spacer()
      }
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
		.pickerStyle(.inline)
	}
	
	@ViewBuilder
	func showContentUnavailableView() -> some View {
		ContentUnavailableView("No Subjects", systemImage: "folder.badge.questionmark", description: Text("Add a subject to get started."))
			.padding()
	}
}
