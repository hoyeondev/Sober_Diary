import SwiftUI
import SwiftData

@main
struct SoberDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: DrinkRecord.self)
    }
}
