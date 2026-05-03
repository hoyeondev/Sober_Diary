import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CalendarView()
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
