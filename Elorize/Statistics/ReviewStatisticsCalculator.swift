import Foundation

/// Handles all review statistics calculations with consistent business logic
struct ReviewStatisticsCalculator {
    
    // MARK: - Quality Score Thresholds
    
    /// Quality scores for different review outcomes
    enum QualityThreshold {
        static let repeatMax = 1      // 0-1: Repeat/Wrong
        static let hardMin = 2        // 2-3: Hard
        static let hardMax = 3
        static let gotItMin = 4       // 4-5: Got it/Correct
    }
    
    // MARK: - Categorization
    
    /// Categorizes a review based on quality score
    static func categorize(quality: Int) -> ReviewCategory {
        if quality >= QualityThreshold.gotItMin {
            return .gotIt
        } else if quality >= QualityThreshold.hardMin {
            return .hard
        } else {
            return .repeat
        }
    }
    
    enum ReviewCategory {
        case gotIt
        case hard
        case `repeat`
    }
    
    // MARK: - Daily Statistics
    
    /// Compute daily stats from review events
    static func dailyStats(from reviewEvents: [ReviewEventEntity], calendar: Calendar = .current) -> [DailyStat] {
        var map: [Date: (correct: Int, hard: Int, wrong: Int)] = [:]
        
        for event in reviewEvents {
            let d = calendar.startOfDay(for: event.timestamp)
            var entry = map[d] ?? (correct: 0, hard: 0, wrong: 0)
            
            // Categorize based on quality score
            switch categorize(quality: event.quality) {
            case .gotIt:
                entry.correct += 1
            case .hard:
                entry.hard += 1
            case .repeat:
                entry.wrong += 1
            }
            
            map[d] = entry
        }
        
        return map.map { key, value in
            DailyStat(id: key, date: key, correct: value.correct, hard: value.hard, wrong: value.wrong)
        }
        .sorted { $0.date < $1.date }
    }
    
    // MARK: - Subject Statistics
    
    /// Count total "Repeat" reviews for cards in a subject
    static func repeatCount(for subjectID: UUID, from flashCards: [FlashCardEntity]) -> Int {
        let subjectCards = flashCards.filter { $0.subject?.id == subjectID }
        
        var count = 0
        for card in subjectCards {
            if let events = card.reviewEvents {
                count += events.filter { event in
                    categorize(quality: event.quality) == .repeat
                }.count
            }
        }
        return count
    }
    
    /// Count total "Hard" reviews for cards in a subject
    static func hardCount(for subjectID: UUID, from flashCards: [FlashCardEntity]) -> Int {
        let subjectCards = flashCards.filter { $0.subject?.id == subjectID }
        
        var count = 0
        for card in subjectCards {
            if let events = card.reviewEvents {
                count += events.filter { event in
                    categorize(quality: event.quality) == .hard
                }.count
            }
        }
        return count
    }
    
    /// Count total "Got it" reviews for cards in a subject
    static func gotItCount(for subjectID: UUID, from flashCards: [FlashCardEntity]) -> Int {
        let subjectCards = flashCards.filter { $0.subject?.id == subjectID }
        
        var count = 0
        for card in subjectCards {
            if let events = card.reviewEvents {
                count += events.filter { event in
                    categorize(quality: event.quality) == .gotIt
                }.count
            }
        }
        return count
    }
    
    // MARK: - Card Statistics
    
    /// Calculate review counts for a single card
    static func reviewCounts(for card: FlashCardEntity) -> (repeat: Int, hard: Int, gotIt: Int) {
        guard let events = card.reviewEvents else {
            return (0, 0, 0)
        }
        
        var repeatCount = 0
        var hardCount = 0
        var gotItCount = 0
        
        for event in events {
            switch categorize(quality: event.quality) {
            case .repeat:
                repeatCount += 1
            case .hard:
                hardCount += 1
            case .gotIt:
                gotItCount += 1
            }
        }
        
        return (repeatCount, hardCount, gotItCount)
    }
}
