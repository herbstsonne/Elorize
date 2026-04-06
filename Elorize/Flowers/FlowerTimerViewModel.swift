import SwiftUI
internal import Combine

@MainActor
class FlowerTimerViewModel: ObservableObject {
    @Published var selectedFlower: FlowerType = .sunflower
    @Published var isTimerRunning = false
    @Published var isPaused = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var progress: Double = 0.0
    @Published var showFlowerPicker = false
    @Published var showCompletionCelebration = false
    
    private var timer: Timer?
    private var startTime: Date?
    private var totalDuration: TimeInterval = 0
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var growthStage: Int {
        // Returns 0-5 based on progress (0 = seed, 5 = full flower)
        Int(progress * 5)
    }
    
    func startTimer() {
        guard !isTimerRunning else { return }
        
        totalDuration = selectedFlower.durationInSeconds
        timeRemaining = totalDuration
        isTimerRunning = true
        isPaused = false
        startTime = Date()
        progress = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resumeTimer() {
        guard isPaused else { return }
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        progress = 0.0
    }
    
    func resetTimer() {
        stopTimer()
        timeRemaining = selectedFlower.durationInSeconds
    }
    
    private func updateTimer() {
        guard timeRemaining > 0 else {
            completeTimer()
            return
        }
        
        timeRemaining -= 1
        progress = 1.0 - (timeRemaining / totalDuration)
    }
    
    private func completeTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        progress = 1.0
        showCompletionCelebration = true
        
        // Hide celebration after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showCompletionCelebration = false
        }
    }
    
    func changeFlower(_ flower: FlowerType) {
        // Only allow changing if timer is not running
        guard !isTimerRunning else { return }
        selectedFlower = flower
        timeRemaining = flower.durationInSeconds
    }
}
