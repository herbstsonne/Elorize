import SwiftUI
import SwiftData

struct AddFlashCardView: View {

  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel = AddFlashCardViewModel()
  
  private var subjects: [SubjectEntity]
  
  init(subjects: [SubjectEntity]) {
    self.subjects = subjects
  }
  
  var body: some View {
		NavigationStack {
			ZStack {
				BackgroundColorView()
				Form {
					showSectionFrontText()
					showSectionBackText()
					showSectionTags()
					showSectionSubject()
				}
				.scrollContentBackground(.hidden)
				.listStyle(.plain)
				.textViewStyle(16)
			}
			.onAppear {
        viewModel.localSubjects = subjects
        if viewModel.selectedSubjectID == nil {
          viewModel.selectedSubjectID = viewModel.localSubjects.first?.id
        }
        viewModel.setContext(context)
        viewModel.loadSubjects(subjects)
			}
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            viewModel.isSaving = true
            // Trim inputs
            let front = viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines)
            let back = viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !front.isEmpty, !back.isEmpty else {
              viewModel.isSaving = false
              return
            }
            // Build tags array from text
            let tags = viewModel.tagsText
              .split(separator: ",")
              .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
              .filter { !$0.isEmpty }
            // Create the flashcard entity
            let card = FlashCardEntity(front: front, back: back, tags: tags)
            // Associate subject if one is selected
            if let selectedID = viewModel.selectedSubjectID,
               let subject = viewModel.localSubjects.first(where: { $0.id == selectedID }) {
              card.subject = subject
            }
            // Insert and save
            context.insert(card)
            do {
              try context.save()
              NotificationCenter.default.post(name: Notification.Name("FlashcardCreated"), object: nil, userInfo: ["cardID": card.id])
              dismiss()
            } catch {
              // Revert saving state on error
              viewModel.isSaving = false
            }
          }
          .disabled(viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    (viewModel.localSubjects.isEmpty && viewModel.selectedSubjectID == nil))
        }
      }
		}
  }
}

private extension AddFlashCardView {
  
  @ViewBuilder
  func showSectionFrontText() -> some View {
    Section("Front") {
      ZStack(alignment: .topLeading) {
        if viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("e.g. hello")
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        TextEditor(text: $viewModel.front)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .frame(minHeight: 80)
      }
    }
  }
  
  @ViewBuilder
  func showSectionBackText() -> some View {
    Section("Back") {
      ZStack(alignment: .topLeading) {
        if viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text("e.g. hola")
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        TextEditor(text: $viewModel.back)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .frame(minHeight: 80)
      }
    }
  }
  
  @ViewBuilder
  func showSectionSubject() -> some View {
    Section("Subject/Category") {
      if viewModel.localSubjects.isEmpty {
        Button {
          viewModel.showingNewSubjectPrompt = true
        } label: {
          Label("Create new subject/category…", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
        .font(.body)
      } else {
        Picker("Subject/Category", selection: $viewModel.selectedSubjectID) {
          Text("None").tag(UUID?.none)
          ForEach(viewModel.localSubjects) { subject in
            Text(subject.name).tag(Optional(subject.id))
          }
        }
        Button {
          viewModel.showingNewSubjectPrompt = true
        } label: {
          Label("+ New subject/category…", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
      }
    }
    .alert("New subject/category", isPresented: $viewModel.showingNewSubjectPrompt) {
      TextField("Name", text: $viewModel.newSubjectName)
      Button("Create") { createSubject() }
      Button("Cancel", role: .cancel) { viewModel.newSubjectName = "" }
    } message: {
      Text("Enter a name for the new subject/category.")
    }
  }
  
  @ViewBuilder
  func showSectionTags() -> some View {
    Section("Tags") {
      TextField("Comma-separated (e.g. greeting, spanish)", text: $viewModel.tagsText)
    }
  }
  
  func createSubject() {
    let trimmed = viewModel.newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let subject = SubjectEntity(name: trimmed)
    context.insert(subject)
    do { try context.save() } catch { /* handle save error if needed */ }
    // Update local subjects and selection
    viewModel.localSubjects.append(subject)
    viewModel.selectedSubjectID = subject.id
    viewModel.newSubjectName = ""
  }
}

