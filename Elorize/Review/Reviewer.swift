import Foundation
import SwiftUI

protocol ReviewerProtocol {
  func registerReview(for entity: FlashCardEntity, quality: Int)
}

struct Reviewer: ReviewerProtocol {

    func registerReview(for entity: FlashCardEntity, quality: Int) {
        registerReview(for: entity, quality: quality, date: Date())
    }

    private func registerReview(for entity: FlashCardEntity, quality: Int, date: Date) {
        var card = entity.card
        card.registerReview(quality: quality, reviewDate: date)

        entity.lastReviewedAt = card.lastReviewedAt
        entity.easeFactor = card.easeFactor
        entity.intervalDays = card.intervalDays
        entity.consecutiveCorrect = card.consecutiveCorrect
    }
}
