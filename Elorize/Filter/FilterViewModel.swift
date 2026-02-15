import SwiftUI
internal import Combine
import SwiftData
import CoreData

final class FilterViewModel: ObservableObject {
  @Published var subjects: [SubjectEntity] = []
  @Published var selectedSubjectID: UUID? = nil
  @Published var reviewFilter: ReviewFilter = .all

  private var cancellables = Set<AnyCancellable>()
  private weak var modelContext: ModelContext?
  private var saveObserver: AnyObject?

  init() {}

  func attach(modelContext: ModelContext) {
    self.modelContext = modelContext
    refetchAll()
    // Optional: observe model context saves to auto-refresh
    saveObserver = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: .main) { [weak self] _ in
      self?.refetchAll()
    }
  }

  func refetchAll() {
    guard let context = modelContext else { return }
    let subjectsDescriptor = FetchDescriptor<SubjectEntity>(sortBy: [SortDescriptor(\.name, order: .forward)])
    do {
      subjects = try context.fetch(subjectsDescriptor)
      // Clear invalid selection if needed
      if let selected = selectedSubjectID, subjects.first(where: { $0.id == selected }) == nil {
        selectedSubjectID = nil
      }
    } catch {
      print("FilterViewModel refetchAll error: \(error)")
    }
  }
  
  deinit {
    if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
  }
}

