import Foundation
import SwiftUI
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
  
  // Compute daily stats from review events using shared calculator
  func dailyStats(from reviewEvents: [ReviewEventEntity]) -> [DailyStat] {
    ReviewStatisticsCalculator.dailyStats(from: reviewEvents, calendar: calendar)
  }

  // Count cards for a subject from a given list (moved from view)
  func cardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    let targetID = subject.id
    var count = 0
    for card in flashCards {
      if card.subject?.id == targetID {
        count += 1
      }
    }
    return count
  }
  
  // Count total "Repeat" reviews for a subject using shared calculator
  func repeatCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    ReviewStatisticsCalculator.repeatCount(for: subject.id, from: flashCards)
  }
  
  // Count total "Hard" reviews for a subject using shared calculator
  func hardCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    ReviewStatisticsCalculator.hardCount(for: subject.id, from: flashCards)
  }
  
  // Count total "Got it" reviews for a subject using shared calculator
  func gotItCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    ReviewStatisticsCalculator.gotItCount(for: subject.id, from: flashCards)
  }

  // Chart helpers to keep logic out of the view
  func chartDomain(for stats: [DailyStat]) -> (first: Date, last: Date, full: ClosedRange<Date>) {
    let first = stats.first?.date ?? Date()
    let last = stats.last?.date ?? Date()
    return (first, last, first ... last)
  }

  func chartStyleScale() -> (domain: [String], range: [Color]) {
    ( ["Got it", "Hard", "Repeat"], [Color.app(.success), Color.app(.warning), Color.app(.error)] )
  }
  
  init(homeViewModel: HomeViewModel) {
    self.homeViewModel = homeViewModel
  }
}

