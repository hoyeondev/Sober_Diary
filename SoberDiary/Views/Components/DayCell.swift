import SwiftUI

struct DayCell: View {
    let date: Date
    let record: DrinkRecord?
    let isToday: Bool
    let isFuture: Bool

    @Environment(AppSettings.self) private var settings

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    private var cellColor: Color {
        guard let record else { return Color("unrecorded") }
        return record.didDrink ? settings.drinkColor : settings.soberColor
    }

    private var textColor: Color {
        if isFuture { return .secondary.opacity(0.5) }
        return record == nil ? .primary.opacity(0.7) : .primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(cellColor)
                .opacity(isFuture ? 0.4 : 1.0)

            if isToday {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 2.5)
            }

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundStyle(textColor)
                if isToday {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack {
        DayCell(date: Date(), record: nil, isToday: true, isFuture: false)
        DayCell(date: Date(), record: DrinkRecord(date: Date(), didDrink: false), isToday: false, isFuture: false)
        DayCell(date: Date(), record: DrinkRecord(date: Date(), didDrink: true), isToday: false, isFuture: false)
        DayCell(date: Date(), record: nil, isToday: false, isFuture: true)
    }
    .padding()
}
