import SwiftUI

struct FilterView: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.dismiss) private var dismiss
  
  @AppStorage("filters.selectedSubjectID") private var storedSelectedSubjectID: String = ""
  @AppStorage("filters.reviewFilter") private var storedReviewFilter: String = ReviewFilter.all.rawValue
  
  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundColorView()
        VStack {
          if viewModel.subjects.isEmpty {
            showContentUnavailableView()
          } else {
            Form {
              showPickerFilterByKnowledge()
                .padding(.bottom, 8)
              showPickerSubject()
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .padding(.horizontal, 20)
            .onChange(of: viewModel.subjects) { oldValue, newValue in
              if let selected = viewModel.selectedSubjectID, newValue.first(where: { $0.id == selected }) == nil {
                viewModel.selectedSubjectID = nil
                storedSelectedSubjectID = ""
              }
              if newValue.isEmpty {
                viewModel.selectedSubjectID = nil
                storedSelectedSubjectID = ""
              }
            }
          }
          Spacer(minLength: 8)
          Spacer()
        }
      }
      .ignoresSafeArea(.keyboard)
      .foregroundStyle(Color.app(.accent_subtle))
      .tint(Color.app(.accent_subtle))
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(Color.clear, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
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

