import Foundation
import SwiftData

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

typealias DrinkRecord = SchemaV3.DrinkRecord

enum PresetDrinkType {
    static let all: [String] = [
        "소주", "맥주", "막걸리", "와인", "양주/위스키", "사케", "칵테일"
    ]
}
