import SwiftUI
import SwiftData

struct AddSubjectView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	@StateObject private var viewModel = AddSubjectViewModel()
	
	var body: some View {
		NavigationStack {
			Form {
				TextField("Subject name", text: $viewModel.name)
				if let error = viewModel.errorMessage {
					Text(error).foregroundStyle(.red)
				}
			}
			.navigationTitle("New Subject")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						if viewModel.save() { dismiss() }
					}
					.disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
				}
			}
			.onAppear { viewModel.setContext(context) }
		}
	}
}
