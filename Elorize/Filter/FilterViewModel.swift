import SwiftUI
internal import Combine

final class FilterViewModel: ObservableObject {
  @Published var subjects: [Subject] = []
  @Published var selectedSubjectID: UUID? = nil
  @Published var reviewFilter: ReviewFilter = .all

  private var cancellables = Set<AnyCancellable>()
  private let store: AppDataStore

  init(store: AppDataStore = .shared) {
    self.store = store
    // Mirror subjects from the store
    store.$subjects
      .receive(on: DispatchQueue.main)
      .assign(to: &$subjects)

    // When subjects change, clear invalid selection
    $subjects
      .combineLatest($selectedSubjectID)
      .sink { [weak self] subjects, selected in
        guard let self = self else { return }
        if let selected, subjects.first(where: { $0.id == selected }) == nil {
          self.selectedSubjectID = nil
        }
      }
      .store(in: &cancellables)
  }
}
