import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \DrinkRecord.date) private var allRecords: [DrinkRecord]
    @StateObject private var viewModel = CalendarViewModel()

    @State private var selectedDate: Date? = nil

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(spacing: 0) {
            streakHeader
            monthNavigationHeader
            weekdayHeader
            calendarGrid
            summaryBanner
            legendView
        }
        .padding(.horizontal, 16)
        .background(Color("appBackground"))
        .gesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    guard abs(horizontal) > vertical else { return }
                    withAnimation(.easeInOut) {
                        if horizontal < 0 { viewModel.nextMonth() }
                        else { viewModel.previousMonth() }
                    }
                }
        )
        .onAppear { viewModel.loadRecords(context: modelContext) }
        .onChange(of: allRecords) { _, _ in
            viewModel.loadRecords(context: modelContext)
        }
        .sheet(item: $selectedDate, onDismiss: {
            viewModel.loadRecords(context: modelContext)
        }) { date in
            DayDetailView(date: date)
        }
    }

    private var streakHeader: some View {
        Group {
            if viewModel.currentSoberStreak > 0 {
                HStack {
                    Text("현재 연속 금주 \(viewModel.currentSoberStreak)일 🔥")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
    }

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut) { viewModel.previousMonth() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(viewModel.monthTitle)
                .font(.system(size: 20, weight: .semibold))
                .onTapGesture {
                    withAnimation(.easeInOut) { viewModel.goToToday() }
                }
            Spacer()
            Button {
                withAnimation(.easeInOut) { viewModel.nextMonth() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.vertical, 8)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(weekdayColor(for: index))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        record: viewModel.record(for: day),
                        isToday: viewModel.isToday(day),
                        isFuture: viewModel.isFuture(day)
                    )
                    .onTapGesture {
                        guard !viewModel.isFuture(day) else { return }
                        selectedDate = day
                    }
                } else {
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private var summaryBanner: some View {
        let summary = viewModel.monthSummary
        let total = summary.sober + summary.drink
        return Group {
            if total > 0 {
                HStack(spacing: 16) {
                    Label("금주 \(summary.sober)일", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(settings.soberColor)
                    Label("음주 \(summary.drink)일", systemImage: "wineglass.fill")
                        .foregroundStyle(settings.drinkColor)
                    Spacer()
                    if summary.drink == 0 && summary.sober > 0 {
                        Text("🎉")
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.top, 16)
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            Spacer()
            legendItem(color: settings.drinkColor, label: "음주")
            legendItem(color: settings.soberColor, label: "금주")
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }

    private func weekdayColor(for index: Int) -> Color {
        switch index {
        case 0: return .red.opacity(0.7)
        case 6: return .blue.opacity(0.7)
        default: return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .navigationTitle("금주일기")
    }
    .modelContainer(for: DrinkRecord.self, inMemory: true)
}
