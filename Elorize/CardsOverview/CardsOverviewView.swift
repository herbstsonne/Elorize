import SwiftUI
import SwiftData

struct CardsOverviewView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.editMode) private var editMode
  
  // Fetch all subjects sorted by name
  @Query(sort: [SortDescriptor(\SubjectEntity.name, order: .forward)])
  private var subjects: [SubjectEntity]
  
  @State private var expandedSubjectIDs: Set<PersistentIdentifier> = []
  
  var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { proxy in
          List {
            if subjects.isEmpty {
              ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
                .textViewStyle(16)
            } else {
              ForEach(subjects) { subject in
                Section {
                  DisclosureGroup(isExpanded: Binding(
                    get: { expandedSubjectIDs.contains(subject.persistentModelID) },
                    set: { isExpanded in
                      if isExpanded {
                        expandedSubjectIDs.insert(subject.persistentModelID)
                      } else {
                        expandedSubjectIDs.remove(subject.persistentModelID)
                      }
                    }
                  )) {
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
                          showFlashcard(card)
                        }
                        .id(card.id)
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
    .onChange(of: editMode?.wrappedValue) { _, newValue in
      editingSubjectName(newValue)
    }
  }
}

// MARK: - ViewBuilder

private extension CardsOverviewView {

  @ViewBuilder
  private func subjectHeader(for subject: SubjectEntity) -> some View {
    HStack {
      if viewModel.editingSubjectID == subject.persistentModelID {
        TextField("Subject name", text: $viewModel.editedSubjectName, onCommit: {
          commitSubjectEdit(subject)
        })
        .textFieldStyle(.roundedBorder)
        .submitLabel(.done)
      } else {
        Text("\(subject.name) (\(subject.flashCardsArray.count))")
          .font(.headline)
      }
      Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
      // Only allow switching into inline edit while in edit mode
      if editMode?.wrappedValue == .active {
        viewModel.editingSubjectID = subject.persistentModelID
        viewModel.editedSubjectName = subject.name
      }
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
  
  @ViewBuilder
  func showFlashcard(_ card: FlashCardEntity) -> some View {
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
      // Stats row
      HStack(spacing: 12) {
        Text("✅ \(card.correctCount)")
        Text("❌ \(card.wrongCount)")
        if let last = card.lastReviewedAt {
          Text("Last: \(last.formatted(date: .abbreviated, time: .shortened))")
        } else {
          Text("Last: —")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .padding(.vertical, 4)
  }
}

private extension CardsOverviewView {
  func commitSubjectEdit(_ subject: SubjectEntity) {
    let newName = viewModel.editedSubjectName
    viewModel.commitSubjectEdit(subject, newName: newName)
    viewModel.editingSubjectID = nil
    viewModel.editedSubjectName = ""
  }
  
  func deleteCards(at offsets: IndexSet, in cards: [FlashCardEntity]) {
    viewModel.deleteCards(at: offsets, in: cards)
  }
  
  func deleteSubjects(at offsets: IndexSet) {
    viewModel.deleteSubjects(at: offsets, subjects: subjects)
  }
  
  func editingSubjectName(_ newValue: EditMode?) {
    switch newValue {
    case .some(.active):
      if let first = subjects.first {
        viewModel.editingSubjectID = first.persistentModelID
        viewModel.editedSubjectName = first.name
      }
    default:
      viewModel.editingSubjectID = nil
      viewModel.editedSubjectName = ""
    }
  }
}

// MARK: - Card detail editor

private struct CardDetailEditor: View {
  
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.dismiss) private var dismiss

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
      Section("Statistics") {
        HStack {
          Text("Correct")
          Spacer()
          Text("\(card.correctCount)")
        }
        HStack {
          Text("Wrong")
          Spacer()
          Text("\(card.wrongCount)")
        }
        HStack {
          Text("Last reviewed")
          Spacer()
          Text(card.lastReviewedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
        }
      }
    }
    .foregroundStyle(Color.app(.accent_subtle))
    .navigationBarTitleDisplayMode(.inline)
    .scrollContentBackground(.hidden)
    .background(BackgroundColorView().ignoresSafeArea())
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          viewModel.save()
          dismiss()
        }
      }
    }
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color.clear, for: .navigationBar)
    .tint(Color.app(.accent_subtle))
  }
}

