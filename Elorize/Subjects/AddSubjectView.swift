import SwiftUI
import SwiftData

struct AddSubjectView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	@State private var name: String = ""
	
	var body: some View {
		NavigationStack {
			Form {
				TextField("Subject name", text: $name)
			}
			.navigationTitle("New Subject")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						let subject = SubjectEntity(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
						context.insert(subject)
						try? context.save()
						dismiss()
					}
					.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
		}
	}
}
