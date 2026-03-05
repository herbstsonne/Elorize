import SwiftUI
import SwiftData

/// Multiple choice quiz view for scanned flashcards
struct MultipleChoiceQuizView: View {
    @Environment(\.dismiss) private var dismiss
    
    let cards: [FlashCard]
    let sourceText: String
    
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var showingResult = false
    @State private var userAnswers: [QuizResult] = []
    @State private var quizCompleted = false
    @State private var score = 0
    @State private var quizQuestions: [QuizQuestion] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                if quizCompleted {
                    resultsView
                } else if !quizQuestions.isEmpty {
                    questionView
                } else {
                    loadingView
                }
            }
            .navigationTitle("Multiple Choice Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !quizCompleted && !quizQuestions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(currentIndex + 1)/\(quizQuestions.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                generateQuizQuestions()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating quiz questions...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 20) {
            // Progress bar
            ProgressView(value: Double(currentIndex), total: Double(quizQuestions.count))
                .tint(Color.app(.accent_default))
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 24) {
                    if currentIndex < quizQuestions.count {
                        let question = quizQuestions[currentIndex]
                        
                        // Question card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Question \(currentIndex + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.app(.background_primary))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.app(.accent_default))
                                    .clipShape(Capsule())
                                
                                Spacer()
                            }
                            
                            Text(question.question)
                                .font(.title3)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.app(.accent_default).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.app(.accent_default), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Answer options
                        VStack(spacing: 12) {
                            ForEach(question.options, id: \.self) { option in
                                answerButton(option: option, question: question)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Next button (shown after selecting an answer)
                        if showingResult {
                            Button {
                                moveToNextQuestion()
                            } label: {
                                Label(currentIndex + 1 < quizQuestions.count ? "Next Question" : "See Results", 
                                      systemImage: currentIndex + 1 < quizQuestions.count ? "arrow.right" : "checkmark")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.app(.accent_default))
                                    .foregroundStyle(Color.app(.background_primary))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .padding(.top)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    @ViewBuilder
    private func answerButton(option: String, question: QuizQuestion) -> some View {
        Button {
            if !showingResult {
                selectAnswer(option, for: question)
            }
        } label: {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundStyle(textColor(for: option, question: question))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showingResult {
                    if option == question.correctAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.app(.gold_primary))
                    } else if option == selectedAnswer {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor(for: option, question: question))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(for: option, question: question), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(showingResult)
        .buttonStyle(.plain)
    }
    
    private func textColor(for option: String, question: QuizQuestion) -> Color {
        if !showingResult {
            return selectedAnswer == option ? Color.app(.accent_default) : .primary
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary)
        } else if option == selectedAnswer {
            return .red
        }
        return .secondary
    }
    
    private func backgroundColor(for option: String, question: QuizQuestion) -> Color {
        if !showingResult {
            return selectedAnswer == option ? Color.app(.accent_default).opacity(0.1) : Color.app(.background_secondary)
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary).opacity(0.15)
        } else if option == selectedAnswer {
            return Color.red.opacity(0.15)
        }
        return Color.app(.background_secondary)
    }
    
    private func borderColor(for option: String, question: QuizQuestion) -> Color {
        if !showingResult {
            return selectedAnswer == option ? Color.app(.accent_default) : Color.clear
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary)
        } else if option == selectedAnswer {
            return .red
        }
        return Color.clear
    }
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score summary
                VStack(spacing: 16) {
                    Image(systemName: scoreIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(scoreColor)
                    
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(score) / \(quizQuestions.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(scoreColor)
                    
                    Text(scoreMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    let percentage = (Double(score) / Double(quizQuestions.count)) * 100
                    Text("\(Int(percentage))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(scoreColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Review answers
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review Answers")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(Array(userAnswers.enumerated()), id: \.offset) { index, result in
                        reviewCard(for: result, index: index)
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        retakeQuiz()
                    } label: {
                        Label("Retake Quiz", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.app(.accent_default))
                            .foregroundStyle(Color.app(.background_primary))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.app(.background_secondary))
                            .foregroundStyle(Color.app(.accent_default))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func reviewCard(for result: QuizResult, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.correct ? Color.app(.gold_primary) : .red)
                
                Text("Question \(index + 1)")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(result.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(alignment: .top, spacing: 4) {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(result.userAnswer)
                        .font(.caption)
                        .foregroundStyle(result.correct ? Color.app(.gold_primary) : .red)
                }
                
                if !result.correct {
                    HStack(alignment: .top, spacing: 4) {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.correctAnswer)
                            .font(.caption)
                            .foregroundStyle(Color.app(.gold_primary))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(result.correct ? Color.app(.gold_primary).opacity(0.1) : Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.correct ? Color.app(.gold_primary) : Color.red, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var scoreIcon: String {
        let percentage = Double(score) / Double(quizQuestions.count)
        if percentage >= 0.9 {
            return "star.fill"
        } else if percentage >= 0.7 {
            return "hand.thumbsup.fill"
        } else if percentage >= 0.5 {
            return "face.smiling"
        } else {
            return "book.fill"
        }
    }
    
    private var scoreColor: Color {
        let percentage = Double(score) / Double(quizQuestions.count)
        if percentage >= 0.9 {
            return .green
        } else if percentage >= 0.7 {
            return .blue
        } else if percentage >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var scoreMessage: String {
        let percentage = Double(score) / Double(quizQuestions.count)
        if percentage >= 0.9 {
            return "Outstanding! 🎉"
        } else if percentage >= 0.7 {
            return "Great job! 👍"
        } else if percentage >= 0.5 {
            return "Good effort! 📚"
        } else {
            return "Keep studying! 💪"
        }
    }
    
    private func generateQuizQuestions() {
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
    
    private func selectAnswer(_ answer: String, for question: QuizQuestion) {
        selectedAnswer = answer
        
        withAnimation(.spring(response: 0.3)) {
            showingResult = true
        }
        
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
    
    private func moveToNextQuestion() {
        if currentIndex + 1 < quizQuestions.count {
            withAnimation {
                currentIndex += 1
                selectedAnswer = nil
                showingResult = false
            }
        } else {
            withAnimation {
                quizCompleted = true
            }
        }
    }
    
    private func retakeQuiz() {
        withAnimation {
            currentIndex = 0
            selectedAnswer = nil
            showingResult = false
            userAnswers = []
            score = 0
            quizCompleted = false
            generateQuizQuestions()
        }
    }
}

// MARK: - Supporting Types

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswer: String
}

struct QuizResult {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let correct: Bool
}

// MARK: - Preview

#Preview {
    MultipleChoiceQuizView(
        cards: [
          FlashCard(front: "What is photosynthesis?", back: "The process by which plants convert sunlight into energy"),
          FlashCard(front: "What is the powerhouse of the cell?", back: "Mitochondria"),
          FlashCard(front: "What is DNA?", back: "Deoxyribonucleic acid"),
          FlashCard(front: "What is the largest organ?", back: "Skin")
        ],
        sourceText: "Sample biology text"
    )
}
