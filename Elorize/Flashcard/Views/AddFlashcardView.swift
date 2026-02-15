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
				viewModel.setRepository(SwiftDataExerciseRepository(context: context))
				if viewModel.selectedSubjectID == nil {
					viewModel.selectedSubjectID = subjects.first?.id
				}
			}
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Save") {
            if viewModel.save(with: subjects) {
              dismiss()
            }
          }
          .disabled(viewModel.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    viewModel.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    (subjects.isEmpty && viewModel.selectedSubjectID == nil))
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
      if subjects.isEmpty {
        Text("No subjects/categories yet. Create one from the Card screen.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        Picker("Subject/Category", selection: $viewModel.selectedSubjectID) {
          Text("None").tag(UUID?.none)
          ForEach(subjects) { subject in
            Text(subject.name).tag(Optional(subject.id))
          }
        }
      }
    }
  }
  
  @ViewBuilder
  func showSectionTags() -> some View {
    Section("Tags") {
      TextField("Comma-separated (e.g. greeting, spanish)", text: $viewModel.tagsText)
    }
  }
}

