import Foundation
import SwiftData

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

@Model
final class DrinkRecord {
    var date: Date
    var didDrink: Bool
    var drinkTypes: [String]
    var drinkLevel: Double
    var memo: String
    var createdAt: Date

    init(date: Date,
         didDrink: Bool = false,
         drinkTypes: [String] = [],
         drinkLevel: Double = 0.5,
         memo: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.didDrink = didDrink
        self.drinkTypes = drinkTypes
        self.drinkLevel = drinkLevel
        self.memo = memo
        self.createdAt = Date()
    }
}

enum PresetDrinkType {
    static let all: [String] = [
        "소주", "맥주", "막걸리", "와인", "양주/위스키", "사케", "칵테일"
    ]
}
