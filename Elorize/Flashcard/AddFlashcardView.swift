import SwiftUI
import SwiftData

struct AddFlashCardView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var context
	
	@State private var front: String = ""
	@State private var back: String = ""
	@State private var note: String = ""
	@State private var tagsText: String = "" // comma-separated
	
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
		let entity = FlashCardEntity(from: card)
		context.insert(entity)
		do { try context.save() } catch { }
		dismiss()
	}
}
