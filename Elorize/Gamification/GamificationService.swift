import Foundation

/// A simple, testable service that manages XP and Level progression.
public final class GamificationService: @unchecked Sendable {
  public private(set) var state: XPLevelState

  /// Configure base XP curve parameters.
  /// Example: baseNextLevelXP = 100, growth = 1.2 means each level requires 20% more XP than the previous.
  private let baseNextLevelXP: Int
  private let growth: Double

  public init(initialXP: Int = 0, initialLevel: Int = 1, baseNextLevelXP: Int = 100, growth: Double = 1.2) {
    self.baseNextLevelXP = max(10, baseNextLevelXP)
    self.growth = max(1.0, growth)
    // Compute derived state for the given starting point
    let (xpForNext, intoCurrent) = GamificationService.split(xp: initialXP, level: initialLevel, base: self.baseNextLevelXP, growth: self.growth)
    self.state = XPLevelState(xp: initialXP, level: initialLevel, xpForNextLevel: xpForNext, xpIntoCurrentLevel: intoCurrent)
  }

  /// Adds XP and handles level-ups as needed.
  @discardableResult
  public func addXP(_ delta: Int) -> XPLevelState {
    guard delta != 0 else { return state }
    var totalXP = max(0, state.xp + delta)
    var level = max(1, state.level)

    // Recompute the level based on total XP.
    while true {
      let (xpForNext, intoCurrent) = GamificationService.split(xp: totalXP, level: level, base: baseNextLevelXP, growth: growth)
      if intoCurrent >= xpForNext { // Should not happen due to split, but be safe
        level += 1
        continue
      }
      state = XPLevelState(xp: totalXP, level: level, xpForNextLevel: xpForNext, xpIntoCurrentLevel: intoCurrent)
      break
    }
    return state
  }

  /// Splits absolute XP into current-level progress and required XP for next level.
  private static func split(xp: Int, level: Int, base: Int, growth: Double) -> (xpForNext: Int, intoCurrent: Int) {
    // Compute how much total XP is required to reach the start of the current level,
    // then subtract from `xp` to get progress within this level.
    let startXP = totalXPRequired(toReachLevel: level, base: base, growth: growth)
    let nextXP = totalXPRequired(toReachLevel: level + 1, base: base, growth: growth)
    let xpInto = max(0, xp - startXP)
    let xpForNext = max(1, nextXP - startXP)
    let clamped = min(xpInto, xpForNext - 1)
    return (xpForNext, clamped)
  }

  /// Returns the cumulative XP required to reach the start of a given level.
  private static func totalXPRequired(toReachLevel level: Int, base: Int, growth: Double) -> Int {
    guard level > 1 else { return 0 }
    var total = 0.0
    var requirement = Double(base)
    for _ in 1..<(level) {
      total += requirement
      requirement *= growth
    }
    return Int(total.rounded())
  }
}
