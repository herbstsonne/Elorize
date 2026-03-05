import SwiftUI

/// View displaying quiz results and review
struct QuizResultsView: View {
    @ObservedObject var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
      ZStack {
        BackgroundColorView()
        ScrollView {
            VStack(spacing: 24) {
              // Score card
              VStack(spacing: 16) {
                Image(systemName: viewModel.scorePercentage >= 0.7 ? "star.fill" : "star")
                  .font(.system(size: 60))
                  .foregroundStyle(viewModel.scorePercentage >= 0.7 ? .yellow : .gray)
                
                Text("Quiz Complete!")
                  .font(.title)
                  .fontWeight(.bold)
                  .foregroundStyle(Color.app(.accent_default))
                
                Text("\(viewModel.score) / \(viewModel.cards.count)")
                  .font(.system(size: 48, weight: .bold))
                  .foregroundStyle(viewModel.scoreColor)
                
                Text(viewModel.scoreMessage)
                  .font(.title3)
                  .foregroundStyle(Color.app(.accent_default))
                
                // Percentage
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
              
              // Review section
              VStack(alignment: .leading, spacing: 16) {
                Text("Review")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundStyle(Color.app(.accent_default))
                  .padding(.horizontal)
                
                ForEach(Array(viewModel.userAnswers.enumerated()), id: \.offset) { index, answer in
                  VStack(alignment: .leading, spacing: 12) {
                    HStack {
                      Image(systemName: answer.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(answer.correct ? Color.app(.success) : Color.app(.error))
                      
                      Text("Question \(index + 1)")
                        .font(.headline)
                        .foregroundStyle(Color.app(.accent_default))
                      
                      Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                      Text("Q: \(answer.question)")
                        .font(.subheadline)
                        .foregroundStyle(Color.app(.accent_default))
                      
                      Text("A: \(answer.answer)")
                        .font(.subheadline)
                        .foregroundStyle(Color.app(.accent_default))
                    }
                  }
                  .padding()
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(answer.correct ? Color.app(.success).opacity(0.1) : Color.app(.error).opacity(0.1))
                  )
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(answer.correct ? Color.app(.success) : Color.app(.error), lineWidth: 1)
                  )
                  .padding(.horizontal)
                }
              }
              .padding(.vertical)
              
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
    }
}

#Preview {
    QuizResultsView(viewModel: {
        let vm = QuizViewModel(
            cards: [
                FlashCard(front: "What is photosynthesis?", back: "The process by which plants convert sunlight into energy"),
                FlashCard(front: "What is the powerhouse of the cell?", back: "Mitochondria"),
                FlashCard(front: "What is DNA?", back: "Deoxyribonucleic acid")
            ],
            sourceText: "Sample text"
        )
        // Simulate completed quiz
        vm.userAnswers = [
            QuizAnswer(question: "What is photosynthesis?", answer: "The process by which plants convert sunlight into energy", correct: true),
            QuizAnswer(question: "What is the powerhouse of the cell?", answer: "Mitochondria", correct: true),
            QuizAnswer(question: "What is DNA?", answer: "Deoxyribonucleic acid", correct: false)
        ]
        vm.currentIndex = 3
        return vm
    }())
}
