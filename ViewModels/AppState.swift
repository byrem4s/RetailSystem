import SwiftUI

@MainActor
final class UserProfileStore: ObservableObject {
    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedTheme = defaults.string(forKey: Keys.theme)
        theme = AppTheme(rawValue: storedTheme ?? "") ?? .system
    }

    private enum Keys {
        static let theme = "user_profile_theme"
    }
}
