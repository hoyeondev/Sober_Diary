import SwiftUI
import SwiftData

@main
struct SoberDiaryApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
        }
        .modelContainer(for: DrinkRecord.self)
    }
}
