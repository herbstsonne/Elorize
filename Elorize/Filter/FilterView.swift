import SwiftUI

struct FilterView: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var vm = FilterViewModel()
  
  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundColorView()
        VStack {
          if vm.subjects.isEmpty {
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
          }
          Spacer(minLength: 8)
          Spacer()
        }
      }
      .ignoresSafeArea(.keyboard)
      .foregroundStyle(Color.app(.accent_subtle))
      .tint(Color.app(.accent_subtle))
      .onAppear {
        vm.updateSubjects(viewModel.subjects)
        // Initialize from HomeViewModel state
        vm.selectedSubjectID = viewModel.selectedSubjectID
        vm.reviewFilter = viewModel.reviewFilter
        // Push changes back to HomeViewModel
        vm.onFilterChanged = { [weak viewModel] subjectID, filter in
          viewModel?.selectedSubjectID = subjectID
          viewModel?.reviewFilter = filter
        }
      }
      .onChange(of: viewModel.subjects) { _, newSubjects in
        vm.updateSubjects(newSubjects)
      }
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
    Picker("FilterByKnowledge", selection: $vm.reviewFilter) {
      ForEach(ReviewFilter.allCases) { f in
        Text(LocalizedStringKey(f.rawValue))
          .tag(f)
          .accentText()
      }
    }
    .pickerStyle(.segmented)
    .tint(Color.app(.accent_default))
  }
  
  @ViewBuilder
  func showPickerSubject() -> some View {
    Picker("Subject", selection: $vm.selectedSubjectID) {
      Text("All")
        .tag(UUID?.none)
        .accentText()
      ForEach(vm.subjects) { subject in
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

