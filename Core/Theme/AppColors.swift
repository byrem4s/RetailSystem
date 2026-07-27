import SwiftUI
import UIKit

struct AppColors {

    // MARK: - Adaptive surfaces

    static let background = Color(
        uiColor: .systemGroupedBackground
    )

    static let card = Color(
        uiColor: .secondarySystemGroupedBackground
    )

    static let elevated = Color(
        uiColor: .tertiarySystemGroupedBackground
    )

    static let field = Color(
        uiColor: .secondarySystemBackground
    )

    // MARK: - Adaptive text

    static let primaryText = Color(
        uiColor: .label
    )

    static let secondaryText = Color(
        uiColor: .secondaryLabel
    )

    static let tertiaryText = Color(
        uiColor: .tertiaryLabel
    )

    // MARK: - Brand and status

    static let blue = Color(
        red: 0.24,
        green: 0.47,
        blue: 0.95
    )

    static let green = Color(
        red: 0.16,
        green: 0.73,
        blue: 0.51
    )

    static let orange = Color(
        red: 0.98,
        green: 0.65,
        blue: 0.18
    )

    static let red = Color(
        red: 0.95,
        green: 0.35,
        blue: 0.35
    )

    // MARK: - Structure

    static let shadow = Color.black.opacity(0.10)

    static let border = Color(
        uiColor: .separator
    )

    static let subtleBorder = Color(
        uiColor: .opaqueSeparator
    ).opacity(0.45)

    static let selection = blue.opacity(0.12)
}


enum AppTheme: String, CaseIterable, Identifiable {

    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .system:
            return "Sistema"
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        }
    }

    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
