import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var records: [Date: DrinkRecord] = [:]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        cal.timeZone = .current
        return cal
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }

    var daysInMonth: [Date?] {
        let cal = calendar
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)),
              let range = cal.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let leadingEmpty = cal.component(.weekday, from: monthStart) - cal.firstWeekday
        let leading = (leadingEmpty + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            if let day = cal.date(byAdding: .day, value: offset, to: monthStart) {
                days.append(day)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    func previousMonth() {
        if let next = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = next
        }
    }

    func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
        }
    }

    func goToToday() {
        currentMonth = Date()
    }

    func loadRecords(context: ModelContext) {
        let descriptor = FetchDescriptor<DrinkRecord>(sortBy: [SortDescriptor(\.date)])
        guard let all = try? context.fetch(descriptor) else {
            records = [:]
            return
        }
        var dict: [Date: DrinkRecord] = [:]
        for record in all {
            let key = calendar.startOfDay(for: record.date)
            dict[key] = record
        }
        records = dict
    }

    func record(for date: Date) -> DrinkRecord? {
        records[calendar.startOfDay(for: date)]
    }

    func isFuture(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        return target > today
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    var monthSummary: (sober: Int, drink: Int) {
        let cal = calendar
        let comps = cal.dateComponents([.year, .month], from: currentMonth)
        var sober = 0
        var drink = 0
        for record in records.values {
            let recordComps = cal.dateComponents([.year, .month], from: record.date)
            if recordComps.year == comps.year && recordComps.month == comps.month {
                if record.didDrink { drink += 1 } else { sober += 1 }
            }
        }
        return (sober, drink)
    }

    var currentSoberStreak: Int {
        let cal = calendar
        var day = cal.startOfDay(for: Date())
        var streak = 0
        while let record = records[day] {
            if record.didDrink { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}
