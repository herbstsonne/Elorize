import Foundation
import SwiftUI
internal import Combine

@MainActor
final class FlashCardViewModel: ObservableObject {
    @Published var isFlipped: Bool = false
    @Published var dragOffset: CGSize = .zero
    @Published var dragRotation: Double = 0

    func flip() {
        isFlipped.toggle()
    }
}
