import SwiftUI
internal import Combine

@MainActor
final class MultipleChoiceQuizViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var selectedAnswer: String?
    @Published var showingResult = false
    @Published var userAnswers: [QuizResult] = []
    @Published var quizCompleted = false
    @Published var score = 0
    @Published var quizQuestions: [QuizQuestion] = []
    
    let cards: [FlashCard]
    let sourceText: String
    
    init(cards: [FlashCard], sourceText: String) {
        self.cards = cards
        self.sourceText = sourceText
    }
    
    func generateQuizQuestions() {
        // Shuffle cards
        let shuffledCards = cards.shuffled()
        
        quizQuestions = shuffledCards.map { card in
            // Generate wrong answers from other cards
            var wrongAnswers = cards
                .filter { $0.back != card.back }
                .map { $0.back }
                .shuffled()
                .prefix(3)
            
            // If we don't have enough wrong answers, generate some generic ones
            while wrongAnswers.count < 3 {
                wrongAnswers.append("Not applicable")
            }
            
            // Combine correct and wrong answers
            var options = Array(wrongAnswers) + [card.back]
            options.shuffle()
            
            return QuizQuestion(
                question: card.front,
                options: options,
                correctAnswer: card.back
            )
        }
    }
    
    func selectAnswer(_ answer: String, for question: QuizQuestion) {
        selectedAnswer = answer
        showingResult = true
        
        let isCorrect = answer == question.correctAnswer
        if isCorrect {
            score += 1
        }
        
        userAnswers.append(QuizResult(
            question: question.question,
            userAnswer: answer,
            correctAnswer: question.correctAnswer,
            correct: isCorrect
        ))
    }
    
    func moveToNextQuestion() {
        if currentIndex + 1 < quizQuestions.count {
            currentIndex += 1
            selectedAnswer = nil
            showingResult = false
        } else {
            quizCompleted = true
        }
    }
    
    func retakeQuiz() {
        currentIndex = 0
        selectedAnswer = nil
        showingResult = false
        userAnswers = []
        score = 0
        quizCompleted = false
        generateQuizQuestions()
    }
    
    var scorePercentage: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(score) / Double(quizQuestions.count)
    }
    
    var scoreIcon: String {
        if scorePercentage >= 0.9 {
            return "star.fill"
        } else if scorePercentage >= 0.7 {
            return "hand.thumbsup.fill"
        } else if scorePercentage >= 0.5 {
            return "face.smiling"
        } else {
            return "book.fill"
        }
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
