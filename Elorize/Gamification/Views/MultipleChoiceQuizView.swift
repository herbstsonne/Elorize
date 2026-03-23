import SwiftUI
import SwiftData

/// Multiple choice quiz view for scanned flashcards
struct MultipleChoiceQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MultipleChoiceQuizViewModel
    
    init(cards: [FlashCard], sourceText: String, onQuizComplete: ((Int, Int) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: MultipleChoiceQuizViewModel(cards: cards, sourceText: sourceText, onQuizComplete: onQuizComplete))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
              BackgroundColorView()
                if viewModel.quizCompleted {
                    resultsView
                } else if !viewModel.quizQuestions.isEmpty {
                    questionView
                } else {
                    loadingView
                }
            }
            .foregroundStyle(Color.app(.accent_default))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !viewModel.quizCompleted && !viewModel.quizQuestions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(viewModel.currentIndex + 1)/\(viewModel.quizQuestions.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                viewModel.generateQuizQuestions()
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
            ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.quizQuestions.count))
                .tint(Color.app(.accent_default))
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.currentIndex < viewModel.quizQuestions.count {
                        let question = viewModel.quizQuestions[viewModel.currentIndex]
                        
                        // Question card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Question \(viewModel.currentIndex + 1)")
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
                                .foregroundStyle(Color.app(.accent_default))
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
                        if viewModel.showingResult {
                            Button {
                                withAnimation {
                                    viewModel.moveToNextQuestion()
                                }
                            } label: {
                                Label(viewModel.currentIndex + 1 < viewModel.quizQuestions.count ? "Next Question" : "See Results", 
                                      systemImage: viewModel.currentIndex + 1 < viewModel.quizQuestions.count ? "arrow.right" : "checkmark")
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
            if !viewModel.showingResult {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.selectAnswer(option, for: question)
                }
            }
        } label: {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundStyle(textColor(for: option, question: question))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if viewModel.showingResult {
                    if option == question.correctAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.app(.gold_primary))
                    } else if option == viewModel.selectedAnswer {
                        Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.app(.error))
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
        .disabled(viewModel.showingResult)
        .buttonStyle(.plain)
    }
    
    private func textColor(for option: String, question: QuizQuestion) -> Color {
        if !viewModel.showingResult {
            return Color.app(.accent_default)
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary)
        } else if option == viewModel.selectedAnswer {
          return Color.app(.error)
        }
        return Color.app(.accent_default)
    }
    
    private func backgroundColor(for option: String, question: QuizQuestion) -> Color {
        if !viewModel.showingResult {
            return viewModel.selectedAnswer == option ? Color.app(.accent_default).opacity(0.1) : Color.app(.background_secondary)
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary).opacity(0.15)
        } else if option == viewModel.selectedAnswer {
          return Color.app(.error)
        }
        return Color.app(.background_secondary)
    }
    
    private func borderColor(for option: String, question: QuizQuestion) -> Color {
        if !viewModel.showingResult {
            return viewModel.selectedAnswer == option ? Color.app(.accent_default) : Color.clear
        }
        
        if option == question.correctAnswer {
            return Color.app(.gold_primary)
        } else if option == viewModel.selectedAnswer {
            return Color.app(.error)
        }
        return Color.clear
    }
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score summary
                VStack(spacing: 16) {
                    Image(systemName: viewModel.scoreIcon)
                        .font(.system(size: 60))
                        .foregroundStyle(viewModel.scoreColor)
                    
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(viewModel.score) / \(viewModel.quizQuestions.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(viewModel.scoreColor)
                    
                    Text(viewModel.scoreMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(viewModel.scorePercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.scoreColor)
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
                    
                    ForEach(Array(viewModel.userAnswers.enumerated()), id: \.offset) { index, result in
                        reviewCard(for: result, index: index)
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        withAnimation {
                            viewModel.retakeQuiz()
                        }
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
                        viewModel.awardXPOnCompletion()
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
                    .foregroundStyle(result.correct ? Color.app(.gold_primary) : Color.app(.error))
                
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
                        .foregroundStyle(result.correct ? Color.app(.gold_primary) : Color.app(.error))
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
                .fill(result.correct ? Color.app(.gold_primary).opacity(0.1) : Color.app(.error).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.correct ? Color.app(.gold_primary) : Color.app(.error), lineWidth: 1)
        )
        .padding(.horizontal)
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
