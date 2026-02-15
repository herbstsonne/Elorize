import SwiftUI
import SwiftData

struct CardsOverviewView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  
  // Fetch all subjects sorted by name
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
  
  // Local state for simple inline editing of subject names
  @State private var editingSubjectID: PersistentIdentifier?
  @State private var editedSubjectName: String = ""
  
  var body: some View {
    NavigationStack {
      VStack {
        List {
          if subjects.isEmpty {
            ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
              .textViewStyle(16)
          } else {
            ForEach(subjects) { subject in
              Section {
                DisclosureGroup {
                  // Show cards for this subject, sorted by createdAt desc
                  let cards = (subject.flashCardsArray).sorted { ($0.createdAt) > ($1.createdAt) }
                  if cards.isEmpty {
                    Text("No cards in this subject")
                      .foregroundStyle(.secondary)
                  } else {
                    ForEach(cards) { card in
                      NavigationLink {
                        CardDetailEditor(card: card)
                          .environmentObject(viewModel)
                      } label: {
                        VStack(alignment: .leading, spacing: 4) {
                          Text(card.front)
                            .font(.headline)
                          Text(card.back)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                          if !card.tags.isEmpty {
                            Text(card.tags.joined(separator: ", "))
                              .font(.caption)
                              .foregroundStyle(.tertiary)
                          }
                        }
                        .padding(.vertical, 4)
                      }
                    }
                    .onDelete { indexSet in
                      deleteCards(at: indexSet, in: cards)
                    }
                  }
                } label: {
                  subjectHeader(for: subject)
                }
              }
            }
            .onDelete(perform: deleteSubjects)
          }
        }
        .foregroundStyle(Color.app(.accent_subtle))
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(BackgroundColorView().ignoresSafeArea())
      }
    }
    .toolbar {
      leadingToolbarItems()
      trailingToolbarItems()
    }
    .sheet(isPresented: $viewModel.showingAddSubject) {
      AddSubjectView()
    }
    .sheet(isPresented: $viewModel.showingAddSheet) {
      AddFlashCardView(subjects: subjects)
    }
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color.clear, for: .navigationBar)
    .tint(Color.app(.accent_subtle))
  }
}

// MARK: - ViewBuilder

private extension CardsOverviewView {

  @ViewBuilder
  private func subjectHeader(for subject: SubjectEntity) -> some View {
    HStack {
      if editingSubjectID == subject.persistentModelID {
        TextField("Subject name", text: $editedSubjectName, onCommit: {
          commitSubjectEdit(subject)
        })
        .textFieldStyle(.roundedBorder)
        .submitLabel(.done)
      } else {
        Text("\(subject.name) (\(subject.flashCardsArray.count))")
          .font(.headline)
      }
      Spacer()
      Button(editingSubjectID == subject.persistentModelID ? "Done" : "Edit") {
        if editingSubjectID == subject.persistentModelID {
          commitSubjectEdit(subject)
        } else {
          editingSubjectID = subject.persistentModelID
          editedSubjectName = subject.name
        }
      }
      .buttonStyle(.borderless)
      .font(.callout)
    }
  }

  @ToolbarContentBuilder
  func leadingToolbarItems() -> some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      EditButton()
    }
  }
  
  @ToolbarContentBuilder
  func trailingToolbarItems() -> some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        viewModel.showingAddSheet = true
      } label: {
        Image(systemName: "plus")
      }
      .accessibilityLabel("Add sample card")
    }
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        viewModel.showingAddSubject = true
      } label: {
        Image(systemName: "folder.badge.plus")
      }
      .accessibilityLabel("Add subject/category")
    }
  }
}

private extension CardsOverviewView {
  func commitSubjectEdit(_ subject: SubjectEntity) {
    let newName = editedSubjectName
    viewModel.commitSubjectEdit(subject, newName: newName)
    editingSubjectID = nil
    editedSubjectName = ""
  }
  
  func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) {
    viewModel.deleteCards(at: offsets, in: cards)
  }
  
  func deleteSubjects(at offsets: IndexSet) {
    viewModel.deleteSubjects(at: offsets, subjects: subjects)
  }
}

// MARK: - Card detail editor

private struct CardDetailEditor: View {
  
  @EnvironmentObject var viewModel: HomeViewModel

  @State var card: FlashCardEntity

  var body: some View {
    Form {
      Section("Front") {
        TextField("Front", text: $card.front)
      }
      Section("Back") {
        TextField("Back", text: $card.back)
      }
      Section("Tags (comma separated)") {
        TextField("tags", text: Binding(
          get: { card.tags.joined(separator: ", ") },
          set: { card.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        ))
      }
    }
    .foregroundStyle(Color.app(.accent_subtle))
    .navigationBarTitleDisplayMode(.inline)
    .scrollContentBackground(.hidden)
    .background(BackgroundColorView().ignoresSafeArea())
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") { viewModel.save() }
      }
    }
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color.clear, for: .navigationBar)
    .tint(Color.app(.accent_subtle))
  }
}

// MARK: - Convenience for subject->cards relationship

extension SubjectEntity {
  var flashCardsArray: [FlashCardEntity] {
    // Attempt to expose a stable array regardless of underlying storage (Set or relationship)
    if let cards = self.cards as? Set<FlashCardEntity> {
      return Array(cards)
    } else if let cards = self.cards as? [FlashCardEntity] {
      return cards
    } else {
      return []
    }
  }
}

