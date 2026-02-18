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
            viewModel.insertFlashcard()
            do {
              try context.save()
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
      Button("Create") { viewModel.createSubject() }
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
}

