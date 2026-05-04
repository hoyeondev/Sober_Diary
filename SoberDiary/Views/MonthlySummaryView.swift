import SwiftUI
import SwiftData

private struct MonthData: Identifiable {
    let id: String
    let title: String
    let sober: Int
    let drink: Int
    var total: Int { sober + drink }
    var soberRatio: Double { total > 0 ? Double(sober) / Double(total) : 0 }
}

struct MonthlySummaryView: View {
    @Query(sort: \DrinkRecord.date, order: .reverse) private var records: [DrinkRecord]

    private var monthlyData: [MonthData] {
        let titleFormatter = DateFormatter()
        titleFormatter.locale = Locale(identifier: "ko_KR")
        titleFormatter.dateFormat = "yyyy년 M월"
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyyMM"

        var groups: [String: (title: String, sober: Int, drink: Int)] = [:]
        for record in records {
            let key = keyFormatter.string(from: record.date)
            var entry = groups[key] ?? (title: titleFormatter.string(from: record.date), sober: 0, drink: 0)
            if record.didDrink { entry.drink += 1 } else { entry.sober += 1 }
            groups[key] = entry
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { MonthData(id: $0.key, title: $0.value.title, sober: $0.value.sober, drink: $0.value.drink) }
    }

    var body: some View {
        Group {
            if monthlyData.isEmpty {
                ContentUnavailableView("기록 없음", systemImage: "chart.bar", description: Text("캘린더에서 날짜를 눌러 기록을 추가하세요."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(monthlyData) { data in
                            MonthSummaryCard(data: data)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color("appBackground"))
            }
        }
    }
}

private struct MonthSummaryCard: View {
    let data: MonthData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if data.drink == 0 && data.sober > 0 {
                    Text("🏆 완전 금주")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 20) {
                statItem(label: "금주", value: data.sober, color: Color("soberBlue"))
                statItem(label: "음주", value: data.drink, color: Color("drinkPink"))
                Spacer()
                Text("총 \(data.total)일 기록")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("drinkPink").opacity(0.25))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("soberBlue"))
                        .frame(width: geo.size.width * data.soberRatio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func statItem(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(value)일")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    MonthlySummaryView()
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
