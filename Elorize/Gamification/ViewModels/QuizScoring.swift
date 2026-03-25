import SwiftUI

/// Shared scoring logic for quiz ViewModels
struct QuizScoring {
    let score: Int
    let totalQuestions: Int
    
    var scorePercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(score) / Double(totalQuestions)
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
            return String(localized: "Outstanding!") + " 🎉"
        } else if scorePercentage >= 0.7 {
            return String(localized: "Great job!") + " 👍"
        } else if scorePercentage >= 0.5 {
            return String(localized: "Good effort!") + " 📚"
        } else {
            return String(localized: "Keep studying!") + " 💪"
        }
    }
}
