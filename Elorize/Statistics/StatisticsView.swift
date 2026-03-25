import SwiftUI
import SwiftData
internal import Combine
import Charts

// Data structure for chart with category for grouping
fileprivate struct ReviewChartData: Identifiable {
    let id = UUID()
    let date: Date
    let category: String
    let count: Int
}

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
                    let repeatCount = statisticsViewModel.repeatCardCount(in: subject, from: flashCards)
                    let hardCount = statisticsViewModel.hardCardCount(in: subject, from: flashCards)
                    let gotItCount = statisticsViewModel.gotItCardCount(in: subject, from: flashCards)
                    SubjectSectionView(
                      subject: subject, 
                      cardCount: count, 
                      repeatCount: repeatCount,
                      hardCount: hardCount,
                      gotItCount: gotItCount
                    )
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

              GeometryReader { geometry in
                  let barWidth: CGFloat = 45 // Width allocated per day
                  let calculatedWidth = CGFloat(stats.count) * barWidth
                  let contentWidth = max(calculatedWidth, 200)
                  let trailingPadding: CGFloat = {
                      if contentWidth > geometry.size.width {
                          // Lots of data: add padding for "Today" positioning
                          return geometry.size.width * 0.5
                      } else {
                          // Less data: fill remaining space to push content left
                          return max(geometry.size.width - contentWidth - 20, 20)
                      }
                  }()
                  
                  ScrollViewReader { proxy in
                      ScrollView(.horizontal, showsIndicators: true) {
                          VStack(spacing: 0) {
                              dailyChart(
                                  stats: stats,
                                  firstDate: firstDate,
                                  lastDate: lastDate,
                                  availableWidth: contentWidth,
                                  barWidth: barWidth
                              )
                              .frame(height: 150)
                              .frame(width: contentWidth)
                              
                              // Spacer for date labels - increased for rotated text
                              Color.clear
                                  .frame(height: 60)
                          }
                          .padding(.trailing, trailingPadding)
                          .padding(.bottom, 15) // Extra padding to prevent clipping
                          .id("chart-content")
                      }
                      .defaultScrollAnchor(.trailing)
                  }
              }
              .frame(height: 225) // Increased height to accommodate rotated labels
              .padding(.bottom, -100) // Reduce space between chart and text below
              
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

        ForEach([Result.gotIt, Result.hard, Result.repeatWrong], id: \.self) { (result: Result) in
            let count: Int = {
                switch result {
                case .gotIt: return stat.correct
                case .hard: return stat.hard
                case .repeatWrong: return stat.wrong
                }
            }()
            let dayValue: PlottableValue<Date> = .value("Day", day, unit: .day)
            let countValue: PlottableValue<Int> = .value("Count", count)

            BarMark(x: dayValue, y: countValue)
                .foregroundStyle(by: .value("Result", result))
                .position(by: .value("Result", result))
        }
    }
  }

  @ViewBuilder
  func dailyChart(stats: [DailyStat], firstDate: Date, lastDate: Date, availableWidth: CGFloat, barWidth: CGFloat) -> some View {
      let successColor: Color = Color.app(.success)
      let hardColor: Color = Color.app(.warning)
      let errorColor: Color = Color.app(.error)

      // Compute y-axis max with explicit types
      let maxYPerDay: [Int] = stats.map { (stat: DailyStat) -> Int in
          stat.correct + stat.hard + stat.wrong
      }
      let maxYValue: Int = maxYPerDay.max() ?? 0
      let yMax: Int = max(Int(Double(maxYValue) * 1.2), 1)

      // Determine the date range to display
      let today: Date = Calendar.current.startOfDay(for: Date())
      
      // Compute full domain based on stats count
      let (statsToDisplay, fullDomain) = computeDisplayParameters(stats: stats, today: today)

      // Build the chart with simpler modifiers
      buildChart(
          stats: stats,
          today: today,
          successColor: successColor,
          hardColor: hardColor,
          errorColor: errorColor,
          fullDomain: fullDomain,
          yMax: yMax,
          barWidth: barWidth
      )
  }
  
  private func computeDisplayParameters(stats: [DailyStat], today: Date) -> ([DailyStat], ClosedRange<Date>) {
      // Show all available data since the chart is now scrollable
      let statsToDisplay = stats
      
      let startDate = statsToDisplay.first?.date ?? today
      let endDate = statsToDisplay.last?.date ?? today
      let fullDomain = startDate ... endDate
      
      return (statsToDisplay, fullDomain)
  }
  
  private func buildChart(
      stats: [DailyStat],
      today: Date,
      successColor: Color,
      hardColor: Color,
      errorColor: Color,
      fullDomain: ClosedRange<Date>,
      yMax: Int,
      barWidth: CGFloat
  ) -> some View {
      // Filter stats to only show those within the domain
      let filteredStats = stats.filter { fullDomain.contains($0.date) }
      
      // Transform data into series format for stacked bars
      let chartData: [ReviewChartData] = filteredStats.flatMap { stat in
          [
              ReviewChartData(date: stat.date, category: "Repeat", count: stat.wrong),
              ReviewChartData(date: stat.date, category: "Hard", count: stat.hard),
              ReviewChartData(date: stat.date, category: "Got it", count: stat.correct)
          ]
      }
      
      // Calculate days in range to determine stride
      let daysInRange = Calendar.current.dateComponents([.day], from: fullDomain.lowerBound, to: fullDomain.upperBound).day ?? 1
      
      let labelStride: Int
      if daysInRange > 30 {
          labelStride = 7
      } else if daysInRange > 14 {
          labelStride = 3
      } else if daysInRange > 7 {
          labelStride = 2
      } else {
          labelStride = 1
      }
      
      return Chart(chartData) { item in
          BarMark(
              x: .value("Day", item.date, unit: .day),
              y: .value("Count", item.count)
          )
          .foregroundStyle(by: .value("Category", item.category))
      }
      .chartForegroundStyleScale([
          "Repeat": errorColor,
          "Hard": hardColor,
          "Got it": successColor
      ])
      .chartXScale(domain: fullDomain)
      .chartYScale(domain: 0 ... yMax)
      .chartLegend(position: .top, alignment: .center, spacing: 8)
      .chartPlotStyle { plotArea in
          plotArea.background(Color.secondary.opacity(0.05))
      }
      .chartYAxis { 
          AxisMarks(position: .leading, values: .automatic) 
      }
      .chartXAxis { 
          AxisMarks(values: .stride(by: .day, count: labelStride)) { value in
              AxisGridLine()
              AxisValueLabel {
                  if let date: Date = value.as(Date.self) {
                      VStack(spacing: 0) {
                          Spacer()
                              .frame(height: 8)
                          Text(date, format: Date.FormatStyle()
                              .locale(Locale(identifier: "en_US"))
                              .month(.twoDigits)
                              .day(.twoDigits))
                          .font(.caption2)
                          .rotationEffect(.degrees(45), anchor: .center)
                          .fixedSize(horizontal: true, vertical: true)
                          .frame(width: 50, height: 50, alignment: .topLeading)
                      }
                  }
              }
          }
      }
  }
  
  @ViewBuilder
  private func DynamicAxisLabel(date date: Date) -> some View {
      Text(date, format: Date.FormatStyle()
          .locale(Locale(identifier: "en_US"))
          .month(.twoDigits)
          .day(.twoDigits))
      .rotationEffect(.degrees(45), anchor: .topLeading)
      .font(.caption2)
      .fixedSize(horizontal: true, vertical: true)
      .padding(.leading, 15)
      .padding(.top, 5)
  }

  @ViewBuilder
  func SubjectSectionView(subject: SubjectEntity, cardCount: Int, repeatCount: Int, hardCount: Int, gotItCount: Int) -> some View {
      Section(subject.name ?? "Unknown") {
          HStack {
              Text("Cards")
              Spacer()
              HStack(spacing: 12) {
                  HStack(spacing: 4) {
                      Image(systemName: "xmark")
                          .font(.caption)
                          .foregroundStyle(Color.app(.error))
                      Text("\(repeatCount)")
                          .foregroundStyle(Color.app(.error))
                  }
                  HStack(spacing: 4) {
                      Image(systemName: "minus")
                          .font(.caption)
                          .foregroundStyle(Color.app(.warning))
                      Text("\(hardCount)")
                          .foregroundStyle(Color.app(.warning))
                  }
                  HStack(spacing: 4) {
                      Image(systemName: "checkmark")
                          .font(.caption)
                          .foregroundStyle(Color.app(.success))
                      Text("\(gotItCount)")
                          .foregroundStyle(Color.app(.success))
                  }
                  Text("\(cardCount)")
                      .fontWeight(.semibold)
              }
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
        let day1 = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let day2 = Calendar.current.date(byAdding: .day, value: -2, to: now)!
      let day3 = Calendar.current.date(byAdding: .day, value: -3, to: now)!
      let day4 = Calendar.current.date(byAdding: .day, value: -4, to: now)!
      let day5 = Calendar.current.date(byAdding: .day, value: -5, to: now)!
      let day6 = Calendar.current.date(byAdding: .day, value: -6, to: now)!
      let day7 = Calendar.current.date(byAdding: .day, value: -7, to: now)!
      let day8 = Calendar.current.date(byAdding: .day, value: -8, to: now)!
      context.insert(ReviewEventEntity(timestamp: day8, isCorrect: true, card: card2))
      context.insert(ReviewEventEntity(timestamp: day7, isCorrect: false, card: card2))
      context.insert(ReviewEventEntity(timestamp: day6, isCorrect: true, card: card2))
      context.insert(ReviewEventEntity(timestamp: day5, isCorrect: false, card: card2))
      context.insert(ReviewEventEntity(timestamp: day4, isCorrect: true, card: card2))
      context.insert(ReviewEventEntity(timestamp: day3, isCorrect: false, card: card2))
      context.insert(ReviewEventEntity(timestamp: day2, isCorrect: true, card: card2))
      context.insert(ReviewEventEntity(timestamp: day2, isCorrect: false, card: card2))
        context.insert(ReviewEventEntity(timestamp: day1, isCorrect: true, card: card1))
        context.insert(ReviewEventEntity(timestamp: day1, isCorrect: false, card: card1))
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

