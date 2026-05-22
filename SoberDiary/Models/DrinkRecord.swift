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
    var drinkAmount: String
    var memo: String
    var createdAt: Date

    init(date: Date,
         didDrink: Bool = false,
         drinkTypes: [String] = [],
         drinkAmount: String = "",
         memo: String = "") {
        self.date = Calendar.current.startOfDay(for: date)
        self.didDrink = didDrink
        self.drinkTypes = drinkTypes
        self.drinkAmount = drinkAmount
        self.memo = memo
        self.createdAt = Date()
    }
}

enum DrinkAmount: String, CaseIterable {
    case light = "조금"
    case moderate = "적당히"
    case heavy = "많이"

    var icon: String {
        switch self {
        case .light:    return "🥃"
        case .moderate: return "🍺"
        case .heavy:    return "🍻"
        }
    }
}

enum PresetDrinkType {
    static let all: [String] = [
        "소주", "맥주", "막걸리", "와인", "양주/위스키", "사케", "칵테일"
    ]
}
