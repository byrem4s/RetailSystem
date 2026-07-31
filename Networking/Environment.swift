import Foundation

enum AppEnvironment {

    static let baseURL: String = {
        let fallback = "http://10.0.0.87:8080"

        if let configured = Bundle.main.object(
            forInfoDictionaryKey: "API_BASE_URL"
        ) as? String {
            let value = configured.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if !value.isEmpty,
               !value.contains("$("),
               let url = URL(string: value),
               let scheme = url.scheme?.lowercased(),
               ["http", "https"].contains(scheme),
               url.host != nil {
                return value.hasSuffix("/")
                    ? String(value.dropLast())
                    : value
            }
        }
        return fallback
    }()
}
