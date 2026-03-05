import SwiftUI
import SwiftData

/// Quiz view for testing knowledge from scanned flashcards
struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: QuizViewModel
    
    init(cards: [FlashCard], sourceText: String) {
        _viewModel = StateObject(wrappedValue: QuizViewModel(cards: cards, sourceText: sourceText))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.quizCompleted {
                    QuizResultsView(viewModel: viewModel)
                } else {
                    QuizQuestionView(viewModel: viewModel)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !viewModel.quizCompleted {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(viewModel.currentIndex + 1)/\(viewModel.cards.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuizView(
        cards: [
            FlashCard(front: "What is photosynthesis?", back: "The process by which plants convert sunlight into energy"),
            FlashCard(front: "What is the powerhouse of the cell?", back: "Mitochondria"),
            FlashCard(front: "What is DNA?", back: "Deoxyribonucleic acid - carries genetic information")
        ],
        sourceText: "Sample text"
    )
}
