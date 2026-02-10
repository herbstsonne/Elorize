import SwiftUI
import SwiftData

struct AddSubjectView: View {

	@Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel = AddSubjectViewModel()
  
  var body: some View {
    NavigationStack {
      ZStack {
        BackgroundColorView()
				Form {
					subjectSection()
        }
				.scrollContentBackground(.hidden)
				.listStyle(.plain)
        .textViewStyle(16)
      }
      .toolbar {
        showToolBar()
      }
			.onAppear {
				viewModel.setRepository(SwiftDataSubjectRepository(context: context))
			}
    }
  }
}

private extension AddSubjectView {
	
	@ToolbarContentBuilder
	func showToolBar() -> some ToolbarContent {
		ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
		ToolbarItem(placement: .confirmationAction) {
			Button("Save") {
				if viewModel.save() { dismiss() }
			}
			.disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
		}
	}
	
	@ViewBuilder
	func subjectSection() -> some View {
		Section("Subject/Category") {
			TextField("e.g. English", text: $viewModel.name)
				.autocorrectionDisabled()
		}
	}
}
