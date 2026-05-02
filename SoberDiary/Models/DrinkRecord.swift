import Foundation
import SwiftData

@Model
final class DrinkRecord {
    var date: Date
    var didDrink: Bool
    var drinkTypes: [String]
    var memo: String
    var createdAt: Date

    init(date: Date,
         didDrink: Bool = false,
         drinkTypes: [String] = [],
         memo: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.didDrink = didDrink
        self.drinkTypes = drinkTypes
        self.memo = memo
        self.createdAt = Date()
    }
}

enum PresetDrinkType {
    static let all: [String] = [
        "소주", "맥주", "막걸리", "와인", "양주/위스키", "사케", "칵테일"
    ]
}
