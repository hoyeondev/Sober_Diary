import SwiftUI
import SwiftData

struct DiaryListView: View {
    @Query(sort: \DrinkRecord.date, order: .reverse) private var records: [DrinkRecord]

    @State private var selectedDate: Date? = nil

    private var groupedRecords: [(title: String, records: [DrinkRecord])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        var result: [(title: String, records: [DrinkRecord])] = []
        var currentKey = ""
        var currentGroup: [DrinkRecord] = []
        for record in records {
            let key = formatter.string(from: record.date)
            if key != currentKey {
                if !currentGroup.isEmpty {
                    result.append((title: currentKey, records: currentGroup))
                }
                currentKey = key
                currentGroup = [record]
            } else {
                currentGroup.append(record)
            }
        }
        if !currentGroup.isEmpty {
            result.append((title: currentKey, records: currentGroup))
        }
        return result
    }

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView("기록 없음", systemImage: "note.text", description: Text("캘린더에서 날짜를 눌러 기록을 추가하세요."))
            } else {
                List {
                    ForEach(groupedRecords, id: \.title) { group in
                        Section(header: Text(group.title).font(.system(size: 13, weight: .semibold))) {
                            ForEach(group.records, id: \.date) { record in
                                DiaryRowView(record: record)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedDate = record.date
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .sheet(item: $selectedDate) { date in
            DayDetailView(date: date)
        }
    }
}

private struct DiaryRowView: View {
    let record: DrinkRecord
    @Environment(AppSettings.self) private var settings

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: record.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(dateLabel)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Label(record.didDrink ? "음주" : "금주",
                      systemImage: record.didDrink ? "wineglass.fill" : "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(record.didDrink ? settings.drinkColor : settings.soberColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(record.didDrink ? settings.drinkColor.opacity(0.15) : settings.soberColor.opacity(0.15)))
            }
            if record.didDrink {
                Text("음주량 \(Int(record.drinkLevel * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(settings.drinkColor)
            }
            if !record.drinkTypes.isEmpty {
                Text(record.drinkTypes.joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if !record.memo.isEmpty {
                Text(record.memo)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DiaryListView()
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
