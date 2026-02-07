import Foundation
import SwiftUI
internal import Combine

@MainActor
final class FlashCardViewModel: ObservableObject {

	let card: FlashCard?
	var onWrong: () -> Void
	var onCorrect: () -> Void
	var onNext: () -> Void

	@Published var isFlipped: Bool = false
	@Published var dragOffset: CGSize = .zero
	@Published var dragRotation: Double = 0

	init(card: FlashCard? = nil,
	     onWrong: @escaping () -> Void = {},
	     onCorrect: @escaping () -> Void = {},
	     onNext: @escaping () -> Void = {}) {
		self.card = card
		self.onWrong = onWrong
		self.onCorrect = onCorrect
		self.onNext = onNext
	}
	
	func flip() {
			isFlipped.toggle()
	}
}

