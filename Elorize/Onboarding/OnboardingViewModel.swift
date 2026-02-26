import Foundation
internal import Combine
import SwiftUI

struct OnboardingScreen: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let systemImage: String
}

@MainActor
final class OnboardingViewModel: ObservableObject {
  @Published var viewIndex: Int = 0
  @Published private(set) var views: [OnboardingScreen]

  init(pages: [OnboardingScreen] = [
    .init(
      title: "Welcome to Elorize",
      message: "Learn efficiently with flashcards. Stay focused with a clean design. Celebrate your progress with fun effects.",
      systemImage: "sparkles"
    ),
    .init(
      title: "Tabs Overview",
      message: "• Exercise: Learn and test your knowledge. Collect XP and level up. Filter cards by knowledge level and/or subject.\n• Cards: Manage subjects/categories and flashcards.\n• Statistics: Find out where you stand.\n",
      systemImage: "rectangle.split.3x1"
    ),
    .init(
      title: "First Steps",
      message: "Start in the Cards tab. Click the plus button to add a new flashcard. Edit the front and back text. You can also create new subjects/categories to group your cards.",
      systemImage: "folder.badge.plus"
    )
  ]) {
    self.views = pages
  }

  var isLastView: Bool { viewIndex >= views.count - 1 }

  func advance() {
    guard viewIndex < views.count - 1 else { return }
    viewIndex += 1
  }

  func skip() {
    // Any analytics or future side effects can go here
  }
}

