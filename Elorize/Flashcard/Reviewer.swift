import Foundation
import SwiftUI

struct Reviewer {

	func registerReview(for entity: FlashCardEntity, quality: Int, date: Date = Date()) {
		var card = entity.value
		card.registerReview(quality: quality, reviewDate: date)
		// Write back updated scheduling fields
		entity.lastReviewedAt = card.lastReviewedAt
		entity.easeFactor = card.easeFactor
		entity.intervalDays = card.intervalDays
		entity.consecutiveCorrect = card.consecutiveCorrect
	}
}
