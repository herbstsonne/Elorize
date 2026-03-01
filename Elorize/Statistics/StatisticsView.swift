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

  init(homeViewModel: HomeViewModel) {
    self.homeViewModel = homeViewModel
    _statisticsViewModel = StateObject(wrappedValue: StatisticsViewModel(homeViewModel: homeViewModel))
  }

    var body: some View {
        NavigationStack {
            List {
              OverallSection(totalCards: statisticsViewModel.totalCards, totalSubjects: statisticsViewModel.totalSubjects)
              DailyPerformanceSection(stats: statisticsViewModel.dailyStats(from: reviewEvents))

                ForEach(subjects, id: \.id) { subject in
                    let count = statisticsViewModel.cardCount(in: subject, from: flashCards)
                    SubjectSectionView(subject: subject, cardCount: count)
                }
            }
            .onAppear { print("subjects:", subjects.count, "flashCards:", flashCards.count, "events:", reviewEvents.count) }
            .onChange(of: subjects) { _, new in print("subjects changed:", new.count) }
            .onChange(of: flashCards) { _, new in print("flashCards changed:", new.count) }
            .onChange(of: reviewEvents) { _, new in print("reviewEvents changed:", new.count) }
            .scrollContentBackground(.hidden)
            .background(BackgroundColorView())        }
    }
}

// MARK: - View Builders
private extension StatisticsView {

  @ViewBuilder
  func OverallSection(totalCards: Int, totalSubjects: Int) -> some View {
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
  func DailyPerformanceSection(stats: [DailyStat]) -> some View {
      Section("Daily Performance") {
          if stats.isEmpty {
              Text("No review activity yet.")
                  .foregroundStyle(.secondary)
          } else {
              let firstDate: Date = stats.first?.date ?? Date()
              let lastDate: Date = stats.last?.date ?? Date()

              dailyChart(
                  stats: stats,
                  firstDate: firstDate,
                  lastDate: lastDate
              )
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
  func chartContent(for stats: [DailyStat]) -> some ChartContent {
    ForEach(stats) { stat in
        let day: Date = stat.date

        ForEach([Result.gotIt, Result.repeatWrong], id: \.self) { result in
            let count: Int = (result == .gotIt) ? stat.correct : stat.wrong

            BarMark(
                x: .value("Day", day, unit: .day),
                y: .value("Count", count)
            )
            .foregroundStyle(by: .value("Result", result))
            .position(by: .value("Result", result))
        }
    }
  }

  @ViewBuilder
  func dailyChart(stats: [DailyStat], firstDate: Date, lastDate: Date) -> some View {
      let fullDomain: ClosedRange<Date> = firstDate ... lastDate
      let resultDomain: [Result] = [.gotIt, .repeatWrong]
      let resultRange: [Color] = [Color.app(.success), Color.app(.error)]
      let maxY: Int = stats.map { $0.correct + $0.wrong }.max() ?? 0
      let yMax: Int = max(Int(Double(maxY) * 1.5), 1)

      Chart {
          chartContent(for: stats)
          // Show today's date as a vertical rule
          let today = Calendar.current.startOfDay(for: Date())
          RuleMark(x: .value("Today", today, unit: .day))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
              .foregroundStyle(Color.app(.accent_subtle))
              .annotation(position: .top, alignment: .center) {
                  Text("Today").font(.caption2).foregroundStyle(Color.app(.accent_subtle))
              }
      }
      .chartXScale(domain: fullDomain)
      .chartScrollableAxes(.horizontal)
      .chartXVisibleDomain(length: 86400 * 7)
      .chartYScale(domain: 0 ... yMax)
      .chartYAxis {
          AxisMarks(position: .leading) {
              AxisGridLine()
              AxisValueLabel()
          }
      }
      .background(Color.secondary.opacity(0.05))
      .chartPlotStyle { plot in plot }
      .chartForegroundStyleScale(domain: resultDomain, range: resultRange)
      .chartXAxis {
          let today = Calendar.current.startOfDay(for: Date())
          AxisMarks(values: .automatic(desiredCount: 6)) { _ in
              AxisGridLine()
            AxisValueLabel(format: .dateTime.locale(Locale(identifier: "en_US")).month(.twoDigits).day(.twoDigits))
          }
          AxisMarks(values: [today]) { _ in
              AxisGridLine()
              AxisValueLabel {
                  Text("Today")
              }
          }
      }
  }

  @ViewBuilder
  func SubjectSectionView(subject: SubjectEntity, cardCount: Int) -> some View {
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
        context.insert(ReviewEventEntity(timestamp: day2, isCorrect: false, card: card2))
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

