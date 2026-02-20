import Foundation
internal import Combine

@MainActor
final class StatisticsViewModel: ObservableObject {

  @Published var homeViewModel: HomeViewModel

  var totalCards: Int { homeViewModel.flashCardEntities.count }
  var totalSubjects: Int { homeViewModel.subjects.count }
  
  let calendar = Calendar.current

  func dayStart(for date: Date) -> Date {
      calendar.startOfDay(for: date)
  }
  
  init(homeViewModel: HomeViewModel) {
    self.homeViewModel = homeViewModel
  }
}

