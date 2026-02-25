import SwiftUI
import SwiftData

struct AllCardsView: View {
  @EnvironmentObject var viewModel: HomeViewModel
  @Environment(\.modelContext) private var context
  @Environment(\.editMode) private var editMode
  @StateObject private var vm = AllCardsViewModel()

  @Query private var subjects: [SubjectEntity]
  @Query(sort: [SortDescriptor(\FlashCardEntity.createdAt, order: .reverse)])
  private var flashCardEntities: [FlashCardEntity]

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
              .onDelete { indexSet in
                deleteSubjects(at: indexSet, subjects: sortedSubjects)
              }
            }
          }
          .foregroundStyle(Color.app(.accent_subtle))
          .listStyle(.insetGrouped)
          .scrollContentBackground(.hidden)
          .background(BackgroundColorView().ignoresSafeArea())
        }
      }
      .searchable(text: $vm.searchText)
      .onChange(of: vm.searchText) { oldValue, newValue in
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
          // When clearing search, don't force any expansion
          // (leave user's expanded/collapsed state as-is)
          return
        }
        expandSubjectsWhenSearching(trimmed)
      }
      .onAppear {
        vm.setRepository(FlashcardRepository(context: context))
        vm.refreshData(with: flashCardEntities, subjects: subjects)
      }
      .onChange(of: flashCardEntities) { _, newCards in
        vm.refreshData(with: newCards, subjects: subjects)
      }
      .onChange(of: subjects) { _, newSubjects in
        vm.refreshData(with: flashCardEntities, subjects: newSubjects)
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
      AddFlashCardView()
        .environmentObject(viewModel)
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

private extension AllCardsView {

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
      Button {
        viewModel.preselectedSubjectForAdd = subject.id
        viewModel.showingAddSheet = true
      } label: {
        Image(systemName: "plus.circle")
          .font(.headline)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Add card to \(subject.name)")
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
        if vm.sort == .createdAt {
          vm.direction = (vm.direction == .ascending) ? .descending : .ascending
        } else {
          vm.sort = .createdAt
          vm.direction = .descending
        }
      } label: {
        let arrow = (vm.sort == .createdAt && vm.direction == .ascending) ? "arrow.up" : "arrow.down"
        Label("Cards: Created", systemImage: arrow)
      }

      // Cards: Last Learnt
      Button {
        if vm.sort == .lastReviewedAt {
          vm.direction = (vm.direction == .ascending) ? .descending : .ascending
        } else {
          vm.sort = .lastReviewedAt
          vm.direction = .descending
        }
      } label: {
        let arrow = (vm.sort == .lastReviewedAt && vm.direction == .ascending) ? "arrow.up" : "arrow/down"
        Label("Cards: Last Learnt", systemImage: arrow)
      }

      // Cards: Front
      Button {
        if vm.sort == .front {
          vm.direction = (vm.direction == .ascending) ? .descending : .ascending
        } else {
          vm.sort = .front
          vm.direction = .ascending
        }
      } label: {
        let arrow = (vm.sort == .front && vm.direction == .ascending) ? "arrow.up" : "arrow.down"
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
    let cards = sortedCards(for: subject, search: vm.searchText, sort: vm.sort, direction: vm.direction)
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
        vm.deleteCards(at: indexSet)
      }
    }
  }
}

private extension AllCardsView {
  func commitSubjectEdit(_ subject: SubjectEntity) {
    let newName = viewModel.editedSubjectName
    viewModel.commitSubjectEdit(subject, newName: newName)
    viewModel.editingSubjectID = nil
    viewModel.editedSubjectName = ""
  }
  
  func deleteSubjects(at offsets: IndexSet, subjects: [SubjectEntity]) {
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

  @Query private var subjects: [SubjectEntity]

  @State private var frontText: String = ""
  @State private var backText: String = ""
  @State private var tagsText: String = ""
  @State private var selectedSubjectID: UUID = UUID()

  var body: some View {
    Form {
      Section("Front") {
        ZStack(alignment: .topLeading) {
          if frontText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Front…")
              .foregroundStyle(.secondary)
              .padding(.horizontal, 5)
              .padding(.vertical, 8)
          }
          TextEditor(text: $frontText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(minHeight: 80)
        }
      }
      Section("Back") {
        ZStack(alignment: .topLeading) {
          if backText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Back…")
              .foregroundStyle(.secondary)
              .padding(.horizontal, 5)
              .padding(.vertical, 8)
          }
          TextEditor(text: $backText)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(minHeight: 80)
        }
      }
      Section("Tags (comma separated)") {
        TextField("tags", text: $tagsText)
      }
      Section("Subject") {
        Picker("Subject", selection: $selectedSubjectID) {
          ForEach(subjects) { subject in
            Text(subject.name).tag(subject.id)
          }
        }
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
    .onAppear {
      frontText = card.front
      backText = card.back
      tagsText = card.tags.joined(separator: ", ")
      if let current = card.subject?.id {
        selectedSubjectID = current
      } else if let first = subjects.first?.id {
        selectedSubjectID = first
      }
    }
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          let tagsArray = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
          viewModel.updateCard(card, front: frontText, back: backText, tags: tagsArray, subjectID: selectedSubjectID)
          dismiss()
        }
      }
    }
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbarBackground(Color.clear, for: .navigationBar)
    .tint(Color.app(.accent_subtle))
  }
}

