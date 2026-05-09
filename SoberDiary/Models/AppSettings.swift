import SwiftUI

@Observable
final class AppSettings {
    var drinkColor: Color
    var soberColor: Color

    init() {
        drinkColor = Self.loadColor(key: "drinkColor") ?? Color("drinkPink")
        soberColor = Self.loadColor(key: "soberColor") ?? Color("soberBlue")
    }

    func save() {
        Self.saveColor(drinkColor, key: "drinkColor")
        Self.saveColor(soberColor, key: "soberColor")
    }

    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "drinkColor")
        UserDefaults.standard.removeObject(forKey: "soberColor")
        drinkColor = Color("drinkPink")
        soberColor = Color("soberBlue")
    }

    private static func saveColor(_ color: Color, key: String) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        UserDefaults.standard.set([Double(r), Double(g), Double(b), Double(a)], forKey: key)
    }

    static func loadColor(key: String) -> Color? {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [Double],
              arr.count == 4 else { return nil }
        return Color(red: arr[0], green: arr[1], blue: arr[2], opacity: arr[3])
    }
}
