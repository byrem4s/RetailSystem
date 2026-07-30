import SwiftUI

struct AppColors {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let canvas = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevated = Color(uiColor: .tertiarySystemGroupedBackground)
    static let field = Color(uiColor: .secondarySystemBackground)

    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let tertiaryText = Color(uiColor: .tertiaryLabel)

    static let navy = Color(
        red: 0.035,
        green: 0.090,
        blue: 0.180
    )
    static let blue = Color(
        red: 0.055,
        green: 0.365,
        blue: 0.930
    )
    static let cyan = Color(
        red: 0.115,
        green: 0.670,
        blue: 0.850
    )
    static let green = Color(
        red: 0.070,
        green: 0.625,
        blue: 0.390
    )
    static let orange = Color(
        red: 0.930,
        green: 0.515,
        blue: 0.090
    )
    static let red = Color(
        red: 0.875,
        green: 0.195,
        blue: 0.205
    )
    static let purple = Color(
        red: 0.405,
        green: 0.255,
        blue: 0.885
    )

    static let border = Color(uiColor: .separator).opacity(0.45)
    static let subtleBorder = Color(uiColor: .separator).opacity(0.22)
    static let shadow = Color.black.opacity(0.08)
    static let selection = blue.opacity(0.12)

    static let brandGradient = LinearGradient(
        colors: [navy, Color(red: 0.045, green: 0.190, blue: 0.410)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
