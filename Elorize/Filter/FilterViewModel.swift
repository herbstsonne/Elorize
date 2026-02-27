internal import Combine
import Foundation
import SwiftUI

@MainActor
final class FilterViewModel: ObservableObject {

  // Persist selections (reuse your existing keys if desired)
  @AppStorage("filters.selectedSubjectID") private var storedSelectedSubjectID: String = ""
  @AppStorage("filters.reviewFilter") private var storedReviewFilter: String = ReviewFilter.all.rawValue

  // Internal flag to avoid triggering didSet during init
  private var isInitializing = true

  @Published var selectedSubjectID: UUID? = nil {
    didSet {
      guard !isInitializing else { return }
      // Persist as string
      storedSelectedSubjectID = selectedSubjectID?.uuidString ?? ""
      // Notify delegate/handler
      onFilterChanged?(selectedSubjectID, reviewFilter)
    }
  }

  @Published var reviewFilter: ReviewFilter = .all {
    didSet {
      guard !isInitializing else { return }
      storedReviewFilter = reviewFilter.rawValue
      onFilterChanged?(selectedSubjectID, reviewFilter)
    }
  }

  // Subjects provided by the caller (the view or parent)
  @Published private(set) var subjects: [SubjectEntity] = []

  // Callback to propagate changes back to HomeViewModel (or other owner)
  var onFilterChanged: ((UUID?, ReviewFilter) -> Void)?

  init(initialSubjects: [SubjectEntity] = [],
       selected: UUID? = nil,
       filter: ReviewFilter? = nil) {
    self.subjects = initialSubjects

    // Compute restored values first
    let restoredSubject = selected ?? UUID(uuidString: storedSelectedSubjectID)
    let restoredFilter = filter ?? ReviewFilter(rawValue: storedReviewFilter) ?? .all

    // Initialize published properties while suppressing didSet side effects
    self.reviewFilter = restoredFilter
    self.selectedSubjectID = restoredSubject

    // Now allow observers to run and persist the restored values
    isInitializing = false
    // Manually persist and notify once with the restored state
    storedSelectedSubjectID = restoredSubject?.uuidString ?? ""
    storedReviewFilter = restoredFilter.rawValue
    onFilterChanged?(selectedSubjectID, reviewFilter)
  }

  func updateSubjects(_ newSubjects: [SubjectEntity]) {
    self.subjects = newSubjects
    // Clear selection if no longer valid
    if let selected = selectedSubjectID, newSubjects.first(where: { $0.id == selected }) == nil {
      selectedSubjectID = nil
    }
    if newSubjects.isEmpty {
      selectedSubjectID = nil
    }
  }

  // Convenience label for UI
  var selectedSubjectName: String {
    guard let id = selectedSubjectID,
          let subject = subjects.first(where: { $0.id == id }) else {
      return "All"
    }
    return subject.name
  }
}

