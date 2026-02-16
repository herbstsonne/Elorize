import Foundation

public enum AppTab: String, CaseIterable, Identifiable, Codable, Hashable {
    case exercise
    case filter
    case cards

    public var id: String { rawValue }
}
