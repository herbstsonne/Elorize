import SwiftUI

struct FilterView: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  
  @AppStorage("filters.selectedSubjectID") private var storedSelectedSubjectID: String = ""
  @AppStorage("filters.reviewFilter") private var storedReviewFilter: String = ReviewFilter.all.rawValue
  
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
          .onChange(of: viewModel.subjects) { oldValue, newValue in
            // If the currently selected subject was deleted, reset selection to All (nil)
            if let selected = viewModel.selectedSubjectID, newValue.first(where: { $0.id == selected }) == nil {
              viewModel.selectedSubjectID = nil
              storedSelectedSubjectID = ""
            }
            // If there are no subjects at all, clear selection and storage
            if newValue.isEmpty {
              viewModel.selectedSubjectID = nil
              storedSelectedSubjectID = ""
            }
          }
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
		.labelsHidden()
    .pickerStyle(.inline)
  }
	
	@ViewBuilder
	func showContentUnavailableView() -> some View {
		ContentUnavailableView("Nothing to filter", systemImage: "rectangle.on.rectangle.slash", description: Text("Add cards in Card tab to start filtering."))
			.padding()
      .textViewStyle(16)
	}
}

