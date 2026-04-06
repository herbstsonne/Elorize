import SwiftUI

enum AppTab: String, Codable, CaseIterable {
    case exercise = "Exercise"
    case cards = "Cards"
    case statistics = "Statistics"
    case garden = "Garden"
    
    var icon: String {
        switch self {
        case .exercise: return "brain.head.profile"
        case .cards: return "rectangle.stack"
        case .statistics: return "chart.bar"
        case .garden: return "camera.macro"  // Flower icon
        }
    }
    
    var title: String {
        rawValue
    }
}
