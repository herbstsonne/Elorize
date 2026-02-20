import SwiftUI

struct DailyStat: Identifiable, Hashable {
    let id: Date
    let date: Date
    let correct: Int
    let wrong: Int
}
