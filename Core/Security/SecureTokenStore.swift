import Foundation
import Security

final class SecureTokenStore {

    static let shared = SecureTokenStore()

    private init() {}

    private let service = "com.mateu.retail.auth"

    var accessToken: String? {
        load(account: "access_token")
    }

    var refreshToken: String? {
        load(account: "refresh_token")
    }

    func save(
        accessToken: String,
        refreshToken: String
    ) throws {
        try save(accessToken, account: "access_token")
        try save(refreshToken, account: "refresh_token")
    }

    func clear() {
        delete(account: "access_token")
        delete(account: "refresh_token")
    }

    private func save(
        _ value: String,
        account: String
    ) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureTokenStoreError.encoding
        }
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureTokenStoreError.keychain(status)
        }
    }

    private func load(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(
            query as CFDictionary,
            &result
        ) == errSecSuccess,
        let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum SecureTokenStoreError: Error {
    case encoding
    case keychain(OSStatus)
}
