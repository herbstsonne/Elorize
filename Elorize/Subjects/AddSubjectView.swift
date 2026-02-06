import SwiftUI
import SwiftData

struct AddSubjectView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	@StateObject private var viewModel = AddSubjectViewModel()
	
	var body: some View {
		NavigationStack {
			ZStack {
				BackgroundColorView()
				Form {
					TextField("Subject/Category", text: $viewModel.name)
					if let error = viewModel.errorMessage {
						Text(error).foregroundStyle(.red)
					}
				}
				.scrollContentBackground(.hidden)
				.listStyle(.plain)
				.textViewStyle(16)
			}
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
