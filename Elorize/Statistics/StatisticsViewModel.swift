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
  
  // Compute daily stats from review events (moved from view)
  func dailyStats(from reviewEvents: [ReviewEventEntity]) -> [DailyStat] {
    var map: [Date: (correct: Int, hard: Int, wrong: Int)] = [:]
    for event in reviewEvents {
      let d = dayStart(for: event.timestamp)
      var entry = map[d] ?? (correct: 0, hard: 0, wrong: 0)
      
      // Categorize based on quality score
      if event.quality >= 4 {
        entry.correct += 1
      } else if event.quality >= 2 {
        entry.hard += 1
      } else {
        entry.wrong += 1
      }
      
      map[d] = entry
    }
    return map.map { key, value in
      DailyStat(id: key, date: key, correct: value.correct, hard: value.hard, wrong: value.wrong)
    }
    .sorted { $0.date < $1.date }
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
  
  // Count "Repeat" cards (wrongCount > 0) for a subject
  func repeatCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    let targetID = subject.id
    var count = 0
    for card in flashCards {
      if card.subject?.id == targetID && card.wrongCount > 0 {
        count += 1
      }
    }
    return count
  }
  
  // Count "Hard" cards (hardCount > 0 and wrongCount == 0) for a subject
  func hardCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    let targetID = subject.id
    var count = 0
    for card in flashCards {
      if card.subject?.id == targetID && card.hardCount > 0 && card.wrongCount == 0 {
        count += 1
      }
    }
    return count
  }
  
  // Count "Got it" cards (correctCount > 0 and hardCount == 0 and wrongCount == 0) for a subject
  func gotItCardCount(in subject: SubjectEntity, from flashCards: [FlashCardEntity]) -> Int {
    let targetID = subject.id
    var count = 0
    for card in flashCards {
      if card.subject?.id == targetID && card.correctCount > 0 && card.hardCount == 0 && card.wrongCount == 0 {
        count += 1
      }
    }
    return count
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

