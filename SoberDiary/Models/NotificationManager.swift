import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let messages: [(title: String, body: String)] = [
        ("오늘도 금주 하실건가요? 💪", "기록을 남겨 건강한 하루를 만들어보세요."),
        ("금주를 향해 gogo! 🏃", "오늘도 한 발짝 더 나아가요!"),
        ("오늘 하루도 맑은 정신으로! ✨", "꾸준한 기록이 변화를 만들어요."),
        ("당신의 건강한 습관을 응원해요 🌟", "함께라면 금주도 어렵지 않아요."),
        ("오늘도 파이팅! 💚", "당신의 도전을 응원합니다."),
        ("건강한 하루 보내고 계신가요? 😊", "오늘의 기록을 남겨보세요."),
        ("금주 챌린지 진행 중! 🔥", "포기하지 말아요, 오늘도 화이팅!"),
    ]

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
        return status == .authorized
    }

    func schedule() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 1...30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            let message = messages[dayOffset % messages.count]
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            content.sound = .default

            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = 15
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "sober_reminder_\(dayOffset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancel() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
