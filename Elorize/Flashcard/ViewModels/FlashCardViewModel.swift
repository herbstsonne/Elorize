import Foundation
import SwiftUI
internal import Combine
import SwiftData

@MainActor
final class FlashCardViewModel: ObservableObject {

	enum HighlightState {
		case front
    case back
		case success
		case error
	}

	struct Actions {
		var onWrong: () -> Void = {}
		var onCorrect: () -> Void = {}
		var onNext: () -> Void = {}
        var onPrevious: () -> Void = {}
	}

	let card: FlashCard?
	var actions: Actions

	@Published var isFlipped: Bool = false
	@Published var dragOffset: CGSize = .zero
	@Published var dragRotation: Double = 0
	@Published var fontSize: CGFloat = 34
	@Published var fontName: String = "System"
	@Published var availableFonts: [String] = FlashCardViewModel.fontNameList

	@Published var showsTextControls: Bool = false
	@Published var isInteracting: Bool = false
	@Published var textAlignment: TextAlignment = .center
	@Published var highlightState: HighlightState = .front
	var alignment: Alignment {
		switch textAlignment {
			case .leading: .leading
			case .center: .center
			case .trailing: .trailing
		}
	}

	@AppStorage("flashcard.fontName") private var storedFontName: String = "System"
	@AppStorage("flashcard.fontSize") private var storedFontSize: Double = 34
	@AppStorage("flashcard.textAlignment") private var storedTextAlignment: String = "center"
  
  private var flashcardsRepository: FlashcardRepository?
	private var cancellables = Set<AnyCancellable>()
  private var modelContext: ModelContext?
	static let fontNameList: [String] = [
		"System",
		"Georgia",
		"Tahoma",
		"Times New Roman",
		"Avenir-Book",
		"HelveticaNeue",
		"Courier New"
	]

	init(
		card: FlashCard? = nil,
		actions: Actions = Actions(),
    flashcardsRepository: FlashcardRepository?,
		fontSize: CGFloat = 34,
		fontName: String = "System",
		availableFonts: [String] = FlashCardViewModel.fontNameList
  ) {
    self.card = card
    self.actions = actions
    self.flashcardsRepository = flashcardsRepository
    let initialName = storedFontName.isEmpty ? fontName : storedFontName
    let initialSize = storedFontSize <= 0 ? Double(fontSize) : storedFontSize
    self.fontName = initialName
    self.fontSize = CGFloat(initialSize)
    self.availableFonts = availableFonts
    
    setTextAlignment()
    loadData()
  }

	func flip() {
    isFlipped.toggle()
    highlightState = isFlipped ? .back : .front
	}
	
	func selectedFont() -> Font {
		if storedFontName == "System" {
			return .system(size: storedFontSize)
		} else {
			return .custom(storedFontName, size: storedFontSize)
		}
	}

	func flashSuccessHighlight(completion: (() -> Void)? = nil) {
    let sideState: HighlightState = isFlipped ? .back : .front
    highlightState = .success
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			withAnimation(.easeInOut) { self.highlightState = sideState }
			completion?()
		}
	}

	func flashErrorHighlight(completion: (() -> Void)? = nil) {
    let sideState: HighlightState = isFlipped ? .back : .front
		highlightState = .error
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			withAnimation(.easeInOut) { self.highlightState = sideState }
			completion?()
		}
	}
  
  func storeReview(isCorrect: Bool) {
    guard let id = card?.id else { return }

    let matchedEntity = flashcardsRepository?.fetchEntity(forId: id)
    if let entity = matchedEntity {
        let event = ReviewEventEntity(timestamp: Date(), isCorrect: isCorrect, card: entity)
        flashcardsRepository?.saveNew(flashCard: entity)
    }

    // Trigger per-outcome action
    if isCorrect {
        actions.onCorrect()
    } else {
        actions.onWrong()
    }

    // Delay before moving to next card to allow highlight animation to be seen
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: 800_000_000)
        actions.onNext()
    }
  }
}

private extension FlashCardViewModel {
	func setTextAlignment() {
		switch storedTextAlignment.lowercased() {
			case "leading", "left":
				self.textAlignment = .leading
			case "trailing", "right":
				self.textAlignment = .trailing
			default:
				self.textAlignment = .center
		}
	}
	
	func loadData() {
        $fontName
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.storedFontName = newValue
            }
            .store(in: &cancellables)

        $fontSize
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .map { Double($0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.storedFontSize = newValue
            }
            .store(in: &cancellables)
		
        $textAlignment
            .dropFirst()
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .map { alignment -> String in
                switch alignment {
                case .leading: return "leading"
                case .center: return "center"
                case .trailing: return "trailing"
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.storedTextAlignment = value
            }
            .store(in: &cancellables)
	}
}

