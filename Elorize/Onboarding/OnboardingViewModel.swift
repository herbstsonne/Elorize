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
      message: "Learn efficiently with flashcards. Sort by subjects/categories. Stay focused with a clean design.",
      systemImage: "sparkles"
    ),
    .init(
      title: "Tabs Overview",
      message: "• Exercise: Learn and test your knowledge.\n• Filter: Filter cards by knowledge level and/or subject.\n• Cards: Manage subjects/categories and flashcards.\n•",
      systemImage: "rectangle.split.3x1"
    ),
    .init(
      title: "First Steps",
      message: "Start in the Cards tab. First create a Subject/Category, then add your first flashcard.",
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

