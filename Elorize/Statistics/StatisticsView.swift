import SwiftUI
import SwiftData
internal import Combine
import Charts

struct StatisticsView: View {
  let homeViewModel: HomeViewModel
  @StateObject private var statisticsViewModel: StatisticsViewModel
    
  @Query(sort: \SubjectEntity.name, order: .forward)
  var subjects: [SubjectEntity]
  
  @Query(sort: \FlashCardEntity.front, order: .forward)
  var flashCards: [FlashCardEntity]
  
  @Query(sort: [SortDescriptor(\ReviewEventEntity.timestamp, order: .forward)])
  var reviewEvents: [ReviewEventEntity]

  var dailyStats: [DailyStat] {
      var map: [Date: (correct: Int, wrong: Int)] = [:]
    for event in reviewEvents {
      let d = statisticsViewModel.dayStart(for: event.timestamp)
          var entry = map[d] ?? (correct: 0, wrong: 0)
          if event.isCorrect { entry.correct += 1 } else { entry.wrong += 1 }
          map[d] = entry
      }
      return map.map { key, value in DailyStat(id: key, date: key, correct: value.correct, wrong: value.wrong) }
                .sorted { $0.date < $1.date }
  }

  init(homeViewModel: HomeViewModel) {
    self.homeViewModel = homeViewModel
    _statisticsViewModel = StateObject(wrappedValue: StatisticsViewModel(homeViewModel: homeViewModel))
  }

    var body: some View {
        NavigationStack {
            List {
              OverallSection(totalCards: statisticsViewModel.totalCards, totalSubjects: statisticsViewModel.totalSubjects)
              DailyPerformanceSection(stats: dailyStats)

                ForEach(subjects, id: \.id) { subject in
                    let stats = subjectStats(for: subject)
                    SubjectSectionView(subject: subject, cardCount: stats)
                }
            }
            .onAppear { print("subjects:", subjects.count, "flashCards:", flashCards.count, "events:", reviewEvents.count) }
            .onChange(of: subjects) { _, new in print("subjects changed:", new.count) }
            .onChange(of: flashCards) { _, new in print("flashCards changed:", new.count) }
            .onChange(of: reviewEvents) { _, new in print("reviewEvents changed:", new.count) }
            .scrollContentBackground(.hidden)
            .background(BackgroundColorView())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Statistics")
                        .font(.headline)
                }
            }
        }
    }
}

private extension StatisticsView {

  @ViewBuilder
  private func OverallSection(totalCards: Int, totalSubjects: Int) -> some View
  {
      Section("Overall") {
          HStack {
              Text("Total Cards")
              Spacer()
              Text("\(totalCards)")
          }
          HStack {
              Text("Total Subjects")
              Spacer()
              Text("\(totalSubjects)")
          }
      }
      .foregroundStyle(Color.app(.accent_subtle))
  }

  @ViewBuilder
  private func DailyPerformanceSection(stats: [DailyStat]) -> some View {
      Section("Daily Performance") {
          if stats.isEmpty {
              Text("No review activity yet.")
                  .foregroundStyle(.secondary)
          } else {
              // Precompute date domains to help the type-checker
              let firstDate: Date = stats.first?.date ?? Date()
              let lastDate: Date = stats.last?.date ?? Date()
              let fullDomain: ClosedRange<Date> = firstDate ... lastDate

              let visibleDomain: ClosedRange<Date> = {
                  let calendar = Calendar.current
                  if let sevenDaysBeforeLast = calendar.date(byAdding: .day, value: -6, to: lastDate) {
                      return max(sevenDaysBeforeLast, firstDate) ... lastDate
                  } else {
                      return fullDomain
                  }
              }()

              // Precompute the foreground style scale mapping
              let resultDomain: [String] = ["Got it", "Repeat"]
              let resultRange: [Color] = [Color.app(.success), Color.app(.error)]

              Chart {
                  chartContent(for: stats)
              }
              .chartXScale(domain: fullDomain)
              .chartScrollableAxes(.horizontal).chartXVisibleDomain(length: 86400 * 7)
              .background(Color.secondary.opacity(0.05))
              .chartPlotStyle { plot in plot }
              .chartForegroundStyleScale(domain: resultDomain, range: resultRange)
              .chartXAxis {
                  AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                      AxisGridLine()
                      AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                  }
              }
              .frame(minHeight: 180)
              Text("Total events: \(reviewEvents.count)")
                  .font(.footnote)
                  .foregroundStyle(Color.app(.accent_subtle))
          }
      }
      .foregroundStyle(Color.app(.accent_subtle))
  }

  // Split chart marks out to reduce generic inference pressure
  @ChartContentBuilder
  private func chartContent(for stats: [DailyStat]) -> some ChartContent {
      ForEach(stats) { stat in
          BarMark(
              x: .value("Day", stat.date, unit: .day),
              y: .value("Count", stat.correct)
          )
          .foregroundStyle(by: .value("Result", "Got it"))
          .position(by: .value("Stack", "Result"))

          BarMark(
              x: .value("Day", stat.date, unit: .day),
              y: .value("Count", stat.wrong)
          )
          .foregroundStyle(by: .value("Result", "Repeat"))
          .position(by: .value("Stack", "Result"))
      }
  }

  @ViewBuilder
  private func SubjectSectionView(subject: SubjectEntity, cardCount: Int) -> some View {
      Section(subject.name ?? "Unknown") {
          HStack {
              Text("Cards in Subject")
              Spacer()
              Text("\(cardCount)")
          }
      }
      .foregroundStyle(Color.app(.accent_subtle))
  }
}

private extension StatisticsView {
  
  func subjectStats(for subject: SubjectEntity) -> Int {
        // Avoid heavy generic inference by not comparing whole entities in a filter closure.
        // Compare stable identifiers instead and use a simple loop the compiler can type-check quickly.
        let targetID = subject.id
        var count = 0
        for card in flashCards {
            if card.subject?.id == targetID {
                count += 1
            }
        }
        return count
    }
}

@MainActor
fileprivate final class StatisticsPreviewModel: ObservableObject {
    let modelContainer: ModelContainer
    @Published var viewModel: HomeViewModel

    init() {
        let schema = Schema([
            FlashCardEntity.self,
            SubjectEntity.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        self.modelContainer = try! ModelContainer(for: schema, configurations: configuration)

        let context = modelContainer.mainContext

      let subject = SubjectEntity(name: "Math")
        subject.id = UUID()
        context.insert(subject)

      let flashcard1 = FlashCard(front: "2+2", back: "4")
      let card1 = FlashCardEntity(from: flashcard1, subject: subject)
        context.insert(card1)

      let flashcard2 = FlashCard(front: "5x5", back: "25")
        let card2 = FlashCardEntity(from: flashcard2, subject: subject)
      context.insert(card2)

        // Sample review events for preview
        let now = Date()
        let day1 = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let day2 = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        context.insert(ReviewEventEntity(timestamp: day1, isCorrect: true, card: card1))
        context.insert(ReviewEventEntity(timestamp: day1, isCorrect: false, card: card1))
        context.insert(ReviewEventEntity(timestamp: day2, isCorrect: true, card: card2))
        context.insert(ReviewEventEntity(timestamp: now, isCorrect: true, card: card2))
        context.insert(ReviewEventEntity(timestamp: now, isCorrect: false, card: card2))

        try! context.save()

        self.viewModel = HomeViewModel()
    }
}

#Preview("StatisticsView") {
  let previewModel = StatisticsPreviewModel()
  let homeVM = previewModel.viewModel
  StatisticsView(homeViewModel: homeVM)
        .environmentObject(homeVM)
        .modelContainer(previewModel.modelContainer)
}

