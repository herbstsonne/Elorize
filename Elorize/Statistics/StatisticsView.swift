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

        ForEach([Result.gotIt, Result.repeatWrong], id: \.self) { (result: Result) in
            let count: Int = (result == .gotIt) ? stat.correct : stat.wrong
            let dayValue: PlottableValue<Date> = .value("Day", day, unit: .day)
            let countValue: PlottableValue<Int> = .value("Count", count)

            BarMark(x: dayValue, y: countValue)
                .foregroundStyle(by: .value("Result", result))
                .position(by: .value("Result", result))
        }
    }
  }

  @ViewBuilder
  func dailyChart(stats: [DailyStat], firstDate: Date, lastDate: Date) -> some View {
      // Precompute domains and constants to reduce generic inference
      let fullDomain: ClosedRange<Date> = firstDate ... lastDate
      let successColor: Color = Color.app(.success)
      let errorColor: Color = Color.app(.error)

      // Compute y-axis max with explicit types
      let maxYPerDay: [Int] = stats.map { (stat: DailyStat) -> Int in
          stat.correct + stat.wrong
      }
      let maxYValue: Int = maxYPerDay.max() ?? 0
      let yMax: Int = max(Int(Double(maxYValue) * 1.5), 1)

      // Precompute today's start of day once
      let today: Date = Calendar.current.startOfDay(for: Date())

      // Build the chart with simpler modifiers
      buildChart(
          stats: stats,
          today: today,
          successColor: successColor,
          errorColor: errorColor,
          fullDomain: fullDomain,
          yMax: yMax
      )
  }
  
  @ViewBuilder
  private func buildChart(
      stats: [DailyStat],
      today: Date,
      successColor: Color,
      errorColor: Color,
      fullDomain: ClosedRange<Date>,
      yMax: Int
  ) -> some View {
      let chart = Chart {
          // Bars for each day/result with explicit styles to avoid scale inference
          ForEach(stats) { (stat: DailyStat) in
              let day: Date = stat.date

              // Correct
              BarMark(
                  x: .value("Day", day, unit: .day),
                  y: .value("Count", stat.correct)
              )
              .foregroundStyle(successColor)
              .position(by: .value("Result", "Correct"))

              // Wrong
              BarMark(
                  x: .value("Day", day, unit: .day),
                  y: .value("Count", stat.wrong)
              )
              .foregroundStyle(errorColor)
              .position(by: .value("Result", "Wrong"))
          }

          // Vertical rule for today with simple annotation
          RuleMark(x: .value("Today", today, unit: .day))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
              .foregroundStyle(Color.app(.accent_subtle))
              .annotation(position: .top, alignment: .center) {
                  Text("Today")
                      .font(.caption2)
                      .foregroundStyle(Color.app(.accent_subtle))
              }
      }
      
      applyChartModifiers(to: chart, fullDomain: fullDomain, yMax: yMax)
  }
  
  @ViewBuilder
  private func applyChartModifiers<Content: ChartContent>(
      to chart: Chart<Content>,
      fullDomain: ClosedRange<Date>,
      yMax: Int
  ) -> some View {
      chart
          .chartXScale(domain: fullDomain)
          .chartScrollableAxes(.horizontal)
          .chartXVisibleDomain(length: 86_400 * 7)
          .chartYScale(domain: 0 ... yMax)
          .chartYAxis { 
              AxisMarks(position: .leading, values: .automatic) 
          }
          .background(Color.secondary.opacity(0.05))
          .chartXAxis { 
              AxisMarks(values: .automatic(desiredCount: 6)) { value in
                  AxisGridLine()
                  if let date: Date = value.as(Date.self) {
                      AxisValueLabel {
                          Text(date, format: Date.FormatStyle()
                              .locale(Locale(identifier: "en_US"))
                              .month(.twoDigits)
                              .day(.twoDigits))
                          .rotationEffect(.degrees(45), anchor: .topLeading)
                          .font(.caption2)
                          .fixedSize()
                          .frame(width: 50, height: 40, alignment: .topLeading)
                          .offset(x: 15, y: 5)
                      }
                  } else {
                      AxisValueLabel()
                  }
              }
          }
          .padding(.bottom, 25)
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

