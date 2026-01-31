import SwiftUI
import SwiftData

struct AddFlashCardView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	
	@State private var front: String = ""
	@State private var back: String = ""
	@State private var note: String = ""
	@State private var tagsText: String = "" // comma-separated
	@State private var selectedSubjectID: UUID?

	private var subjects: [SubjectEntity]
	
    init(subjects: [SubjectEntity]) {
        self.subjects = subjects
        // Default to the first subject if available
        _selectedSubjectID = State(initialValue: subjects.first?.id)
    }
	
	var body: some View {
		NavigationStack {
			Form {
				Section("Front") {
					TextField("e.g. hello", text: $front)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("Back") {
					TextField("e.g. hola", text: $back)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				Section("Note") {
					TextField("Optional note", text: $note)
				}
				Section("Tags") {
					TextField("Comma-separated (e.g. greeting, spanish)", text: $tagsText)
				}
                Section("Subject") {
                    if subjects.isEmpty {
                        Text("No subjects yet. Create one from the Home screen.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Subject", selection: $selectedSubjectID) {
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
					Button("Save") { save() }
						.disabled(front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
		}
	}
	
	private func save() {
		let tags = tagsText
			.split(separator: ",")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
		let card = FlashCard(front: front, back: back, note: note.isEmpty ? nil : note, tags: tags)
		let subject = subjects.first(where: { $0.id == selectedSubjectID })
		let entity = FlashCardEntity(from: card, subject: subject)
		context.insert(entity)
		do { try context.save() } catch { }
		dismiss()
	}
}
