internal import Combine
import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AllCardsViewModel: ObservableObject {

  // MARK: - Inputs from UI
  @Published var searchText: String = ""
  @Published var sort: CardSortCriterion = .createdAt
  @Published var direction: SortDirection = .descending

  // Selection (optional, if your view supports multi-select)
  @Published var selectedCardIDs: Set<UUID> = []

  // MARK: - Data source
  @Published private(set) var allCards: [FlashCardEntity] = []
  @Published private(set) var subjects: [SubjectEntity] = []

  // MARK: - Dependencies
  private var flashcardsRepository: FlashcardRepositoryProtocol?

  // MARK: - Derived collections

  var filteredCards: [FlashCardEntity] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return allCards }
    // Simple search across front/back/tags
    return allCards.filter { card in
      let haystack = [
        card.front,
        card.back,
        card.tags.joined(separator: ", ")
      ].joined(separator: " ").lowercased()
      return haystack.contains(trimmed.lowercased())
    }
  }

  var sortedCards: [FlashCardEntity] {
    let base = filteredCards
    switch sort {
    case .front:
      switch direction {
      case .ascending:
        return base.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedAscending }
      case .descending:
        return base.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedDescending }
      }
    case .createdAt:
      switch direction {
      case .ascending:
        return base.sorted { $0.createdAt < $1.createdAt }
      case .descending:
        return base.sorted { $0.createdAt > $1.createdAt }
      }
    case .lastReviewedAt:
      switch direction {
      case .ascending:
        return base.sorted { ($0.lastReviewedAt ?? .distantPast) < ($1.lastReviewedAt ?? .distantPast) }
      case .descending:
        return base.sorted { ($0.lastReviewedAt ?? .distantPast) > ($1.lastReviewedAt ?? .distantPast) }
      }
    }
  }

  // MARK: - Lifecycle

  init(flashcardsRepository: FlashcardRepositoryProtocol? = nil) {
    self.flashcardsRepository = flashcardsRepository
  }

  func setRepository(_ repository: FlashcardRepositoryProtocol?) {
    self.flashcardsRepository = repository
  }

  // MARK: - Data loading

  func refreshData(with cards: [FlashCardEntity], subjects: [SubjectEntity]) {
    self.allCards = cards
    self.subjects = subjects
    // Optional: clear selections that no longer exist
    selectedCardIDs = selectedCardIDs.intersection(Set(cards.map { $0.id }))
  }

  // MARK: - Actions

  func deleteCards(at offsets: IndexSet) {
    flashcardsRepository?.deleteCards(at: offsets, in: sortedCards)
    // Optimistically update UI list
    let idsToRemove = offsets.map { sortedCards[$0].id }
    allCards.removeAll { idsToRemove.contains($0.id) }
  }

  func deleteSelected() {
    guard !selectedCardIDs.isEmpty else { return }
    let source = sortedCards
    let indices = IndexSet(source.enumerated().compactMap { idx, card in
      selectedCardIDs.contains(card.id) ? idx : nil
    })
    flashcardsRepository?.deleteCards(at: indices, in: source)
    // Optimistic removal
    allCards.removeAll { selectedCardIDs.contains($0.id) }
    selectedCardIDs.removeAll()
  }

  // MARK: - Formatting helpers (optional)

  func tagsString(for card: FlashCardEntity) -> String {
    card.tags.joined(separator: ", ")
  }

  func lastReviewedString(for card: FlashCardEntity) -> String {
    card.lastReviewedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—"
  }
}
