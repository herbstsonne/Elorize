import SwiftUI
internal import Combine

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var showingAnswer = false
    @Published var userAnswers: [QuizAnswer] = []
    @Published var quizCompleted = false
    @Published var score = 0
    
    let cards: [FlashCard]
    let sourceText: String
    
    init(cards: [FlashCard], sourceText: String) {
        self.cards = cards
        self.sourceText = sourceText
    }
    
    func answerQuestion(correct: Bool) {
        // Record answer
        let answer = QuizAnswer(
            question: cards[currentIndex].front,
            answer: cards[currentIndex].back,
            correct: correct
        )
        userAnswers.append(answer)
        
        if correct {
            score += 1
        }
        
        // Move to next question
        if currentIndex + 1 < cards.count {
            currentIndex += 1
            showingAnswer = false
        } else {
            // Quiz completed
            quizCompleted = true
        }
    }
    
    func retakeQuiz() {
        currentIndex = 0
        showingAnswer = false
        userAnswers = []
        score = 0
        quizCompleted = false
    }
    
    var scorePercentage: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(score) / Double(cards.count)
    }
    
    var scoreColor: Color {
        if scorePercentage >= 0.9 {
            return Color.app(.success)
        } else if scorePercentage >= 0.7 {
            return .blue
        } else if scorePercentage >= 0.5 {
            return .orange
        } else {
            return Color.app(.error)
        }
    }
    
    var scoreMessage: String {
        if scorePercentage >= 0.9 {
            return "Outstanding! 🎉"
        } else if scorePercentage >= 0.7 {
            return "Great job! 👍"
        } else if scorePercentage >= 0.5 {
            return "Good effort! 📚"
        } else {
            return "Keep studying! 💪"
        }
    }
}
