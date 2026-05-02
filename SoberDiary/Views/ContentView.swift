import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CalendarView()
                .navigationTitle("금주일기")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
