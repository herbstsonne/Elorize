import SwiftUI

/// View displaying the current quiz question and answer reveal
struct QuizQuestionView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
      ZStack {
        BackgroundColorView()
        VStack(spacing: 24) {
          ProgressView(value: Double(viewModel.currentIndex), total: Double(viewModel.cards.count))
            .tint(Color.app(.accent_default))
            .padding(.horizontal)
          
          Spacer()
          
          if viewModel.currentIndex < viewModel.cards.count {
            let card = viewModel.cards[viewModel.currentIndex]
            
            VStack(spacing: 20) {
              // Question card
              VStack(spacing: 16) {
                Text("Question")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundStyle(Color.app(.accent_default))
                
                Text(card.front)
                  .font(.title2)
                  .fontWeight(.medium)
                  .multilineTextAlignment(.center)
                  .foregroundStyle(Color.app(.accent_default))
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
              if viewModel.showingAnswer {
                VStack(spacing: 16) {
                  Text(String(localized:"Answer"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.app(.gold_primary))
                  
                  Text(card.back)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.app(.gold_primary))
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
                  Text(String(localized:"Did you get it right?"))
                    .font(.headline)
                    .foregroundStyle(Color.app(.accent_default))
                  
                  HStack(spacing: 16) {
                    Button {
                      withAnimation {
                        viewModel.answerQuestion(correct: false)
                      }
                    } label: {
                      Label("Incorrect", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.app(.error))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                      withAnimation {
                        viewModel.answerQuestion(correct: true)
                      }
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
                    viewModel.showingAnswer = true
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
    }
}

#Preview {
    QuizQuestionView(viewModel: QuizViewModel(
        cards: [
            FlashCard(front: "What is photosynthesis?", back: "The process by which plants convert sunlight into energy"),
            FlashCard(front: "What is the powerhouse of the cell?", back: "Mitochondria")
        ],
        sourceText: "Sample text"
    ))
}
