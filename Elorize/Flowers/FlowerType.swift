import Foundation
import SwiftUI

enum FlowerType: String, Codable, CaseIterable, Identifiable {
    case vergissmeinnicht = "Vergissmeinnicht"
    case schneegloeckchen = "Schneeglöckchen"
    case sunflower = "Sunflower"
    case lavender = "Lavender"
    case mohnblume = "Mohnblume"
    
    var id: String { rawValue }
    
    /// Duration in minutes
    var duration: Int {
        switch self {
        case .vergissmeinnicht: return 15
        case .schneegloeckchen: return 20
        case .sunflower: return 30
        case .lavender: return 45
        case .mohnblume: return 60
        }
    }
    
    /// Duration in seconds (for actual timer)
    var durationInSeconds: TimeInterval {
        TimeInterval(duration * 60)
    }
    
    /// Emoji representation for visual display
    var emoji: String {
        switch self {
        case .vergissmeinnicht: return "🌸"  // Forget-me-not (using cherry blossom)
        case .schneegloeckchen: return "🤍"  // Snowdrop (using white heart)
        case .sunflower: return "🌻"
        case .lavender: return "💜"  // Lavender (using purple heart)
        case .mohnblume: return "🌺"  // Poppy
        }
    }
    
    /// Color scheme for the flower
    var color: Color {
        switch self {
        case .vergissmeinnicht: return .blue
        case .schneegloeckchen: return Color(white: 0.95)
        case .sunflower: return .yellow
        case .lavender: return .purple
        case .mohnblume: return .red
        }
    }
    
    /// Display name with duration
    var displayName: String {
        "\(duration) min \(rawValue)"
    }
}
