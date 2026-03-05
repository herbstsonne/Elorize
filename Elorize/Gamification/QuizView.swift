import SwiftUI
import SwiftData

/// Quiz view for testing knowledge from scanned flashcards
struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    let cards: [FlashCard]
    let sourceText: String
    
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var userAnswers: [QuizAnswer] = []
    @State private var quizCompleted = false
    @State private var score = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                if quizCompleted {
                    // Results view
                    quizResultsView
                } else {
                    // Quiz in progress
                    quizQuestionView
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !quizCompleted {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(currentIndex + 1)/\(cards.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var quizQuestionView: some View {
        VStack(spacing: 24) {
            // Progress bar
            ProgressView(value: Double(currentIndex), total: Double(cards.count))
                .tint(Color.app(.accent_default))
                .padding(.horizontal)
            
            Spacer()
            
            if currentIndex < cards.count {
                let card = cards[currentIndex]
                
                VStack(spacing: 20) {
                    // Question card
                    VStack(spacing: 16) {
                        Text("Question")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Text(card.front)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.app(.accent_default).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.app(.accent_default), lineWidth: 2)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Answer reveal
                    if showingAnswer {
                        VStack(spacing: 16) {
                            Text("Answer")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(card.back)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.app(.gold_primary).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.app(.gold_primary), lineWidth: 2)
                                )
                        )
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                        
                        // Self-grading buttons
                        VStack(spacing: 12) {
                            Text("Did you get it right?")
                                .font(.headline)
                            
                            HStack(spacing: 16) {
                                Button {
                                    answerQuestion(correct: false)
                                } label: {
                                    Label("Incorrect", systemImage: "xmark.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button {
                                    answerQuestion(correct: true)
                                } label: {
                                    Label("Correct", systemImage: "checkmark.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.app(.gold_primary))
                                        .foregroundStyle(Color.app(.background_primary))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                    } else {
                        // Show answer button
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showingAnswer = true
                            }
                        } label: {
                            Label("Show Answer", systemImage: "eye.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.app(.accent_default))
                                .foregroundStyle(Color.app(.background_primary))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var quizResultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score card
                VStack(spacing: 16) {
                    Image(systemName: Double(score) >= Double(cards.count) * 0.7 ? "star.fill" : "star")
                        .font(.system(size: 60))
                        .foregroundStyle(Double(score) >= Double(cards.count) * 0.7 ? .yellow : .gray)
                    
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(score) / \(cards.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(scoreColor)
                    
                    Text(scoreMessage)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    // Percentage
                    let percentage = (Double(score) / Double(cards.count)) * 100
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
                
                // Review section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ForEach(Array(userAnswers.enumerated()), id: \.offset) { index, answer in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: answer.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(answer.correct ? .green : .red)
                                
                                Text("Question \(index + 1)")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Q: \(answer.question)")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                
                                Text("A: \(answer.answer)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(answer.correct ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(answer.correct ? Color.green : Color.red, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
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
                .padding(.bottom)
            }
            .padding(.vertical)
        }
    }
    
    private var scoreColor: Color {
        let percentage = Double(score) / Double(cards.count)
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
        let percentage = Double(score) / Double(cards.count)
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
    
    private func answerQuestion(correct: Bool) {
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
            withAnimation {
                currentIndex += 1
                showingAnswer = false
            }
        } else {
            // Quiz completed
            withAnimation {
                quizCompleted = true
            }
        }
    }
    
    private func retakeQuiz() {
        withAnimation {
            currentIndex = 0
            showingAnswer = false
            userAnswers = []
            score = 0
            quizCompleted = false
        }
    }
}

// MARK: - Supporting Types

struct QuizAnswer {
    let question: String
    let answer: String
    let correct: Bool
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
