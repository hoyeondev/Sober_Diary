import SwiftUI
import SwiftData

@main
struct SoberDiaryApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .task {
                    if settings.isNotificationEnabled {
                        let granted = await NotificationManager.shared.requestPermission()
                        if granted {
                            NotificationManager.shared.schedule()
                        }
                    }
                }
        }
        .modelContainer(for: DrinkRecord.self)
    }
}
