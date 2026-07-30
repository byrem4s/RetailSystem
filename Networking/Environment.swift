import Foundation

enum Environment {

    static let baseURL: String = {
        if let configured = Bundle.main.object(
            forInfoDictionaryKey: "API_BASE_URL"
        ) as? String {
            let value = configured.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            if !value.isEmpty {
                return value.hasSuffix("/")
                    ? String(value.dropLast())
                    : value
            }
        }
        return "http://10.0.0.87:8080"
    }()
}
