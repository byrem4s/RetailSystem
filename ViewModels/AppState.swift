import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var refreshID = UUID()

    @Published var selectedExecutionID: Int?
    @Published var selectedHistoricalLabel: String?

    @Published private(set) var activityHistoryRequestID = UUID()
    @Published private(set) var shouldFocusActivityHistory = false

    private init() {}

    var isHistoricalMode: Bool {
        selectedExecutionID != nil
    }

    func refreshSystem() {
        refreshID = UUID()
    }

    func refresh() {
        refreshID = UUID()
    }

    func requestActivityHistoryFocus() {

        shouldFocusActivityHistory = true
        activityHistoryRequestID = UUID()
    }

    func consumeActivityHistoryFocus() {
        shouldFocusActivityHistory = false
    }

    func selectHistoricalAnalysis(
        executionID: Int,
        label: String
    ) {

        selectedExecutionID = executionID
        selectedHistoricalLabel = label

        refreshSystem()
    }

    func clearHistoricalAnalysis() {

        selectedExecutionID = nil
        selectedHistoricalLabel = nil

        refreshSystem()
    }
}

@MainActor
final class UserProfileStore: ObservableObject {

    @Published var firstName: String {
        didSet {
            defaults.set(firstName, forKey: Keys.firstName)
        }
    }

    @Published var lastName: String {
        didSet {
            defaults.set(lastName, forKey: Keys.lastName)
        }
    }

    @Published var branch: String {
        didSet {
            defaults.set(branch, forKey: Keys.branch)
        }
    }

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {

        self.defaults = defaults

        firstName = defaults.string(
            forKey: Keys.firstName
        ) ?? ""

        lastName = defaults.string(
            forKey: Keys.lastName
        ) ?? ""

        branch = defaults.string(
            forKey: Keys.branch
        ) ?? ""

        let storedTheme = defaults.string(
            forKey: Keys.theme
        )

        theme = AppTheme(
            rawValue: storedTheme ?? ""
        ) ?? .light
    }

    var fullName: String {

        let values = [firstName, lastName]
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        return values.isEmpty
        ? "Equipo"
        : values.joined(separator: " ")
    }

    var displayBranch: String {

        let value = branch.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty
        ? "Todas las sucursales"
        : value
    }

    var initials: String {

        let firstInitial = firstName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map(String.init)

        let lastInitial = lastName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
            .map(String.init)

        let result = [firstInitial, lastInitial]
            .compactMap { $0 }
            .joined()
            .uppercased()

        return result.isEmpty ? "U" : result
    }

    func seedIfNeeded(
        name: String,
        branch: String
    ) {

        if firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty,
        lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {

            let parts = name
                .split(
                    separator: " ",
                    omittingEmptySubsequences: true
                )
                .map(String.init)

            if let first = parts.first,
               first.lowercased() != "equipo" {

                firstName = first

                if parts.count > 1 {
                    lastName = parts.dropFirst().joined(separator: " ")
                }
            }
        }

        if self.branch.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty,
        !branch.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty,
        branch.lowercased() != "todas las sucursales" {

            self.branch = branch
        }
    }

    func updateProfile(
        firstName: String,
        lastName: String,
        branch: String,
        theme: AppTheme
    ) {

        self.firstName = firstName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        self.lastName = lastName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        self.branch = branch.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        self.theme = theme
    }

    private enum Keys {
        static let firstName = "user_profile_first_name"
        static let lastName = "user_profile_last_name"
        static let branch = "user_profile_branch"
        static let theme = "user_profile_theme"
    }
}
