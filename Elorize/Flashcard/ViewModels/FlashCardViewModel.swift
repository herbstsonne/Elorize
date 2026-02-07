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
	@Published var fontSize: CGFloat = 34
	@Published var fontName: String = "System"
	@Published var availableFonts: [String] = [
			"System",
			"Georgia",
			"Times New Roman",
			"Avenir-Book",
			"HelveticaNeue",
			"Courier New"
	]

	@Published var showsTextControls: Bool = false
	@Published var isInteracting: Bool = false
	@Published var textAlignment: TextAlignment = .center

	@AppStorage("flashcard.fontName") private var storedFontName: String = "System"
	@AppStorage("flashcard.fontSize") private var storedFontSize: Double = 34
	@AppStorage("flashcard.textAlignment") private var storedTextAlignment: String = "center"

	private var cancellables = Set<AnyCancellable>()

	init(
		card: FlashCard? = nil,
		onWrong: @escaping () -> Void = {},
		onCorrect: @escaping () -> Void = {},
		onNext: @escaping () -> Void = {},
		 fontSize: CGFloat = 34,
		 fontName: String = "System",
		 availableFonts: [String] = [
			"System",
			"Georgia",
			"Tahoma",
			"Times New Roman",
			"Avenir-Book",
			"HelveticaNeue",
			"Courier New"
		 ]
	) {
		self.card = card
		self.onWrong = onWrong
		self.onCorrect = onCorrect
		self.onNext = onNext
		let initialName = storedFontName.isEmpty ? fontName : storedFontName
		let initialSize = storedFontSize <= 0 ? Double(fontSize) : storedFontSize
		self.fontName = initialName
		self.fontSize = CGFloat(initialSize)
		self.availableFonts = availableFonts

        switch storedTextAlignment.lowercased() {
        case "leading", "left":
            self.textAlignment = .leading
        case "trailing", "right":
            self.textAlignment = .trailing
        default:
            self.textAlignment = .center
        }

		$fontName
				.dropFirst()
				.sink { [weak self] newValue in
						self?.storedFontName = newValue
				}
				.store(in: &cancellables)

		$fontSize
				.dropFirst()
				.map { Double($0) }
				.sink { [weak self] newValue in
						self?.storedFontSize = newValue
				}
				.store(in: &cancellables)

        $textAlignment
            .dropFirst()
            .sink { [weak self] newValue in
                switch newValue {
                case .leading:
                    self?.storedTextAlignment = "leading"
                case .center:
                    self?.storedTextAlignment = "center"
                case .trailing:
                    self?.storedTextAlignment = "trailing"
                default:
                    self?.storedTextAlignment = "center"
                }
            }
            .store(in: &cancellables)
	}
	
	func flip() {
		isFlipped = !isFlipped
	}
	
	func selectedFont() -> Font {
		if storedFontName == "System" {
			return .system(size: storedFontSize)
		} else {
			return .custom(storedFontName, size: storedFontSize)
		}
	}
}

