import SwiftUI
import SwiftData

struct AddFlashCardView: View {

	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	
	@StateObject private var viewModel = AddFlashCardViewModel()
	
	private var subjects: [SubjectEntity]
	
	init(subjects: [SubjectEntity]) {
			self.subjects = subjects
	}
	
	var body: some View {
		NavigationStack {
			Form {
				Section("Front") {
					TextField("e.g. hello", text: $viewModel.front)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("Back") {
					TextField("e.g. hola", text: $viewModel.back)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("Tags") {
					TextField("Comma-separated (e.g. greeting, spanish)", text: $viewModel.tagsText)
				}
                Section("Subject") {
                    if subjects.isEmpty {
                        Text("No subjects yet. Create one from the Home screen.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Subject", selection: $viewModel.selectedSubjectID) {
                            Text("None").tag(UUID?.none)
                            ForEach(subjects) { subject in
                                Text(subject.name).tag(Optional(subject.id))
                            }
                        }
                    }
                }
			}
			.navigationTitle("New Card")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						if viewModel.save(with: subjects) {
							dismiss()
						}
					}
					.disabled(viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				viewModel.setContext(context)
				if viewModel.selectedSubjectID == nil {
					viewModel.selectedSubjectID = subjects.first?.id
				}
			}
		}
	}
}
