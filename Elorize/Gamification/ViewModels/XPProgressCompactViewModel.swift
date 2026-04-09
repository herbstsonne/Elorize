import SwiftUI
internal import Combine

@MainActor
final class XPProgressCompactViewModel: ObservableObject {
    @Published var showingDetails = false
    @Published var showCelebration = false
    
    weak var homeViewModel: HomeViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var lastObservedLevel: Int?
    
    init(homeViewModel: HomeViewModel? = nil) {
        self.homeViewModel = homeViewModel
    }
    
    // MARK: - Computed Properties
    
    var level: Int {
        homeViewModel?.xpState.level ?? 1
    }
    
    var levelProgress: Double {
        homeViewModel?.xpState.levelProgress ?? 0.0
    }
    
    var totalXP: Int {
        homeViewModel?.xpState.xp ?? 0
    }
    
    var xpIntoCurrentLevel: Int {
        homeViewModel?.xpState.xpIntoCurrentLevel ?? 0
    }
    
    var xpForNextLevel: Int {
        homeViewModel?.xpState.xpForNextLevel ?? 500
    }
    
    var xpRemaining: Int {
        max(0, xpForNextLevel - xpIntoCurrentLevel)
    }
    
    var correctAnswersNeeded: Int {
        xpRemaining / 5
    }
    
    var levelProgressPercentage: Int {
        Int(levelProgress * 100)
    }
    
    // MARK: - Accessibility
    
    var accessibilityLabel: String {
        "Level \(level), progress \(levelProgressPercentage) percent"
    }
    
    var accessibilityHint: String {
        "Opens XP and level details."
    }
    
    // MARK: - Actions
    
    func openDetails() {
        showingDetails = true
    }
    
    func closeDetails() {
        showingDetails = false
    }
    
    func configure(with homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
        lastObservedLevel = homeViewModel.xpState.level
    }
    
    func handleLevelChange(_ newLevel: Int) {
        let previous = lastObservedLevel ?? newLevel
        if newLevel > previous {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCelebration = true
            }
            // Auto-hide after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.showCelebration = false
                }
            }
        }
        lastObservedLevel = newLevel
    }
}

