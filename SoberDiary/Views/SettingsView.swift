import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    private let drinkPresets: [(name: String, color: Color)] = [
        ("기본", Color(red: 1.0, green: 0.70, blue: 0.78)),
        ("레드", Color(red: 1.0, green: 0.38, blue: 0.38)),
        ("오렌지", Color(red: 1.0, green: 0.62, blue: 0.25)),
        ("퍼플", Color(red: 0.72, green: 0.37, blue: 0.92)),
        ("로즈", Color(red: 0.88, green: 0.22, blue: 0.45)),
    ]

    private let soberPresets: [(name: String, color: Color)] = [
        ("기본", Color(red: 0.68, green: 0.91, blue: 0.96)),
        ("시안", Color(red: 0.28, green: 0.79, blue: 0.89)),
        ("민트", Color(red: 0.40, green: 0.88, blue: 0.72)),
        ("그린", Color(red: 0.35, green: 0.78, blue: 0.42)),
        ("블루", Color(red: 0.33, green: 0.58, blue: 0.95)),
    ]

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                colorRow(
                    title: "음주 색상",
                    icon: "wineglass.fill",
                    color: $settings.drinkColor,
                    presets: drinkPresets
                )
            } header: {
                Text("색상")
            } footer: {
                Text("달력, 리스트, 통계에 표시되는 음주/금주 색상을 변경합니다.")
            }

            Section {
                colorRow(
                    title: "금주 색상",
                    icon: "checkmark.seal.fill",
                    color: $settings.soberColor,
                    presets: soberPresets
                )
            }

            Section {
                Toggle(isOn: $settings.isNotificationEnabled) {
                    Label("매일 알림", systemImage: "bell.fill")
                }
                .onChange(of: settings.isNotificationEnabled) { _, enabled in
                    settings.saveNotificationEnabled()
                    if enabled {
                        Task {
                            let granted = await NotificationManager.shared.requestPermission()
                            if granted {
                                NotificationManager.shared.schedule()
                            } else {
                                settings.isNotificationEnabled = false
                                settings.saveNotificationEnabled()
                            }
                        }
                    } else {
                        NotificationManager.shared.cancel()
                    }
                }
                if settings.isNotificationEnabled {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("매일 오후 3시에 알림이 발송됩니다.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("알림")
            }

            Section {
                Button(role: .destructive) {
                    settings.resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Text("색상 기본값으로 초기화")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("설정")
        .onChange(of: settings.drinkColor) { _, _ in settings.save() }
        .onChange(of: settings.soberColor) { _, _ in settings.save() }
    }

    @ViewBuilder
    private func colorRow(
        title: String,
        icon: String,
        color: Binding<Color>,
        presets: [(name: String, color: Color)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color.wrappedValue)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                ColorPicker("", selection: color, supportsOpacity: false)
                    .labelsHidden()
            }

            HStack(spacing: 14) {
                ForEach(presets, id: \.name) { preset in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle().strokeBorder(
                                    isSelected(color.wrappedValue, preset: preset.color)
                                        ? Color.primary : Color.clear,
                                    lineWidth: 2.5
                                )
                            )
                            .shadow(color: preset.color.opacity(0.45), radius: 3, x: 0, y: 1)
                            .onTapGesture { color.wrappedValue = preset.color }
                        Text(preset.name)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    private func isSelected(_ color: Color, preset: Color) -> Bool {
        let c1 = UIColor(color)
        let c2 = UIColor(preset)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: nil)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: nil)
        return abs(r1 - r2) < 0.02 && abs(g1 - g2) < 0.02 && abs(b1 - b2) < 0.02
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppSettings())
}
