import Foundation

/// Immutable value type representing XP/Level progress.
public struct XPLevelState: Equatable, Sendable {
  public let xp: Int
  public let level: Int
  /// XP required to reach the next level from the current one.
  public let xpForNextLevel: Int
  /// XP already earned within the current level (0...xpForNextLevel).
  public let xpIntoCurrentLevel: Int

  public init(xp: Int, level: Int, xpForNextLevel: Int, xpIntoCurrentLevel: Int) {
    self.xp = max(0, xp)
    self.level = max(1, level)
    self.xpForNextLevel = max(1, xpForNextLevel)
    self.xpIntoCurrentLevel = min(max(0, xpIntoCurrentLevel), xpForNextLevel)
  }

  /// A value between 0 and 1 indicating progress within the current level.
  public var levelProgress: Double {
    guard xpForNextLevel > 0 else { return 0 }
    return Double(xpIntoCurrentLevel) / Double(xpForNextLevel)
  }
}
