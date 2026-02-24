import SwiftUI
import SwiftData

struct CardsOverviewView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.editMode) private var editMode
  
  // Fetch all subjects (we'll sort locally based on UI state)
  @Query private var subjects: [SubjectEntity]
  
  var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { proxy in
          List {
            let sortedSubjects = sortedSubjectsArray()
            if subjects.isEmpty {
              ContentUnavailableView("No Cards", systemImage: "rectangle.on.rectangle.slash", description: Text("Add your first flashcard to get started."))
                .textViewStyle(16)
            } else {
              ForEach(sortedSubjects) { subject in
                Section {
                  DisclosureGroup(isExpanded: Binding(
                    get: { viewModel.expandedSubjectIDs.contains(subject.persistentModelID) },
                    set: { isExpanded in
                      if isExpanded {
                        viewModel.expandedSubjectIDs.insert(subject.persistentModelID)
                      } else {
                        viewModel.expandedSubjectIDs.remove(subject.persistentModelID)
                      }
                    }
                  )) {
                    cardsList(for: subject)
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
      .searchable(text: $viewModel.searchText)
      .onChange(of: viewModel.searchText) { oldValue, newValue in
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
          // When clearing search, don't force any expansion
          // (leave user's expanded/collapsed state as-is)
          return
        }
        expandSubjectsWhenSearching(trimmed)
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

  func expandSubjectsWhenSearching(_ trimmed: String) {
    var newExpanded: Set<PersistentIdentifier> = []
    for subject in subjects {
      let matches = subject.searchCards(matching: trimmed)
      if !matches.isEmpty {
        newExpanded.insert(subject.persistentModelID)
      }
    }
    viewModel.expandedSubjectIDs = newExpanded
  }

  func sortedSubjectsArray() -> [SubjectEntity] {
    return subjects.sorted { a, b in
      switch viewModel.subjectSort {
      case .name:
        switch viewModel.subjectSortDirection {
        case .ascending:
          return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        case .descending:
          return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
        }
      }
    }
  }

  @ViewBuilder
  func subjectHeader(for subject: SubjectEntity) -> some View {
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
      sortMenu()
    }
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
  func sortMenu() -> some View {
    Menu {
      // Subject: Name
      Button {
        if viewModel.subjectSort == .name {
          viewModel.subjectSortDirection = (viewModel.subjectSortDirection == .ascending) ? .descending : .ascending
        } else {
          viewModel.subjectSort = .name
          viewModel.subjectSortDirection = .ascending
        }
      } label: {
        let arrow = viewModel.subjectSortDirection == .ascending ? "arrow.up" : "arrow.down"
        Label("Subject: Name", systemImage: arrow)
      }

      // Cards: Created
      Button {
        if viewModel.cardSort == .createdAt {
          viewModel.cardSortDirection = (viewModel.cardSortDirection == .ascending) ? .descending : .ascending
        } else {
          viewModel.cardSort = .createdAt
          viewModel.cardSortDirection = .descending
        }
      } label: {
        let arrow = (viewModel.cardSort == .createdAt && viewModel.cardSortDirection == .ascending) ? "arrow.up" : "arrow.down"
        Label("Cards: Created", systemImage: arrow)
      }

      // Cards: Last Learnt
      Button {
        if viewModel.cardSort == .lastReviewedAt {
          viewModel.cardSortDirection = (viewModel.cardSortDirection == .ascending) ? .descending : .ascending
        } else {
          viewModel.cardSort = .lastReviewedAt
          viewModel.cardSortDirection = .descending
        }
      } label: {
        let arrow = (viewModel.cardSort == .lastReviewedAt && viewModel.cardSortDirection == .ascending) ? "arrow.up" : "arrow.down"
        Label("Cards: Last Learnt", systemImage: arrow)
      }

      // Cards: Front
      Button {
        if viewModel.cardSort == .front {
          viewModel.cardSortDirection = (viewModel.cardSortDirection == .ascending) ? .descending : .ascending
        } else {
          viewModel.cardSort = .front
          viewModel.cardSortDirection = .ascending
        }
      } label: {
        let arrow = (viewModel.cardSort == .front && viewModel.cardSortDirection == .ascending) ? "arrow.up" : "arrow.down"
        Label("Cards: Front", systemImage: arrow)
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
    }
    .accessibilityLabel("Sort")
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
  
  func sortedCards(for subject: SubjectEntity, search: String, sort: CardSortCriterion, direction: SortDirection) -> [FlashCardEntity] {
    let base = subject.searchCards(matching: search)
    switch sort {
    case .front:
      switch direction {
      case .ascending:
        return base.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedAscending }
      case .descending:
        return base.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedDescending }
      }
    case .createdAt:
      switch direction {
      case .ascending:
        return base.sorted { $0.createdAt < $1.createdAt }
      case .descending:
        return base.sorted { $0.createdAt > $1.createdAt }
      }
    case .lastReviewedAt:
      // Treat nil as very old when ascending, very new when descending
      switch direction {
      case .ascending:
        return base.sorted { ( $0.lastReviewedAt ?? .distantPast ) < ( $1.lastReviewedAt ?? .distantPast ) }
      case .descending:
        return base.sorted { ( $0.lastReviewedAt ?? .distantPast ) > ( $1.lastReviewedAt ?? .distantPast ) }
      }
    }
  }
  
  @ViewBuilder
  func cardsList(for subject: SubjectEntity) -> some View {
    let cards = sortedCards(for: subject, search: viewModel.searchText, sort: viewModel.cardSort, direction: viewModel.cardSortDirection)
    if cards.isEmpty {
      Text("No matching cards")
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

