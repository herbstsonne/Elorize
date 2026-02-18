import SwiftUI
import SwiftData

struct AddFlashCardView: View {

  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  
  @StateObject private var viewModel = AddFlashCardViewModel()
  @State private var localSubjects: [SubjectEntity] = []
  @State private var showingNewSubjectPrompt = false
  @State private var newSubjectName: String = ""
  @State private var isSaving: Bool = false
  
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
        self.localSubjects = subjects
        if viewModel.selectedSubjectID == nil {
          viewModel.selectedSubjectID = localSubjects.first?.id
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
            isSaving = true
            if viewModel.save() {
              dismiss()
            } else {
              isSaving = false
            }
          }
          .disabled(viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    (localSubjects.isEmpty && viewModel.selectedSubjectID == nil))
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
      if localSubjects.isEmpty {
        Button {
          showingNewSubjectPrompt = true
        } label: {
          Label("Create new subject/category…", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.borderless)
        .font(.body)
      } else {
        Picker("Subject/Category", selection: $viewModel.selectedSubjectID) {
          Text("None").tag(UUID?.none)
          ForEach(localSubjects) { subject in
            Text(subject.name).tag(Optional(subject.id))
          }
          Text("+ New subject/category…").tag(UUID?.none)
        }
        .onChange(of: viewModel.selectedSubjectID) { _, newValue in
          if !isSaving, newValue == nil {
            showingNewSubjectPrompt = true
          }
        }
      }
    }
    .alert("New subject/category", isPresented: $showingNewSubjectPrompt) {
      TextField("Name", text: $newSubjectName)
      Button("Create") { createSubject() }
      Button("Cancel", role: .cancel) { newSubjectName = "" }
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
    let trimmed = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let subject = SubjectEntity(name: trimmed)
    context.insert(subject)
    do { try context.save() } catch { /* handle save error if needed */ }
    // Update local subjects and selection
    localSubjects.append(subject)
    viewModel.selectedSubjectID = subject.id
    newSubjectName = ""
  }
}

