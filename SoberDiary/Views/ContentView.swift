import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DiaryListView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("리스트", systemImage: "list.bullet")
            }

            NavigationStack {
                CalendarView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("캘린더", systemImage: "calendar")
            }

            NavigationStack {
                MonthlySummaryView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("월별 요약", systemImage: "chart.bar.fill")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
