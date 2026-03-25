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
    @Published var hasAwardedXP = false
    
    let cards: [FlashCard]
    let sourceText: String
    let onQuizComplete: ((Int, Int) -> Void)?
    
    init(cards: [FlashCard], sourceText: String, onQuizComplete: ((Int, Int) -> Void)? = nil) {
        self.cards = cards
        self.sourceText = sourceText
        self.onQuizComplete = onQuizComplete
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
            print("✅ Multiple Choice Quiz completed with score: \(score)/\(quizQuestions.count)")
            quizCompleted = true
        }
    }
    
    func awardXPOnCompletion() {
        guard !hasAwardedXP else {
            print("⚠️ XP already awarded for this quiz")
            return
        }
        print("✅ Awarding XP on Done button press")
        onQuizComplete?(score, quizQuestions.count)
        hasAwardedXP = true
    }
    
    func retakeQuiz() {
        currentIndex = 0
        selectedAnswer = nil
        showingResult = false
        userAnswers = []
        score = 0
        quizCompleted = false
        hasAwardedXP = false
        generateQuizQuestions()
    }
    
    var scoring: QuizScoring {
        QuizScoring(score: score, totalQuestions: quizQuestions.count)
    }
    
    var scorePercentage: Double {
        scoring.scorePercentage
    }
    
    var scoreIcon: String {
        scoring.scoreIcon
    }
    
    var scoreColor: Color {
        scoring.scoreColor
    }
    
    var scoreMessage: String {
        scoring.scoreMessage
    }
}
