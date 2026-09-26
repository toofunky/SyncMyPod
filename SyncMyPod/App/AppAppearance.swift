import SwiftUI

enum AppAppearance: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    static let storageKey = "appAppearance"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    static func toggled(from current: ColorScheme) -> AppAppearance {
        current == .dark ? .light : .dark
    }

    static func toggleSymbolName(for current: ColorScheme) -> String {
        current == .dark ? "sun.max" : "moon"
    }

    static func toggleTitle(for current: ColorScheme) -> String {
        current == .dark ? "Light Mode" : "Dark Mode"
    }
}
