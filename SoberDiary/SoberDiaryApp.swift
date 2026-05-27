import SwiftUI
import SwiftData

@main
struct SoberDiaryApp: App {
    @State private var settings = AppSettings()

    let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: DrinkRecord.self,
                migrationPlan: DrinkRecordMigrationPlan.self
            )
        } catch {
            // 기존 비버전 스토어와 충돌 시 스토어 삭제 후 재생성
            let storeDir = URL.applicationSupportDirectory
            if let files = try? FileManager.default.contentsOfDirectory(at: storeDir, includingPropertiesForKeys: nil) {
                for file in files where file.lastPathComponent.hasSuffix(".store")
                    || file.lastPathComponent.hasSuffix(".store-shm")
                    || file.lastPathComponent.hasSuffix(".store-wal") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            do {
                return try ModelContainer(
                    for: DrinkRecord.self,
                    migrationPlan: DrinkRecordMigrationPlan.self
                )
            } catch let e {
                fatalError("ModelContainer 생성 실패: \(e)")
            }
        }
    }()

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
        .modelContainer(container)
    }
}
