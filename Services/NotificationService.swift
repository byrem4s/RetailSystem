import Foundation

final class NotificationService {
    func fetchNotifications(
        unreadOnly: Bool = false
    ) async throws -> [NotificationDTO] {
        let query = unreadOnly ? "?unread_only=true" : ""
        return try await APIClient.shared.fetch(
            endpoint: "/v2/notifications\(query)",
            responseType: [NotificationDTO].self
        )
    }

    func fetchUnreadCount() async throws -> Int {
        let response = try await APIClient.shared.fetch(
            endpoint: "/v2/notifications/unread-count",
            responseType: NotificationUnreadCountDTO.self
        )
        return response.count
    }

    func markAsRead(
        notificationID: Int
    ) async throws -> NotificationDTO {
        try await APIClient.shared.put(
            endpoint: "/v2/notifications/\(notificationID)/read",
            responseType: NotificationDTO.self
        )
    }

    func markAllAsRead() async throws {
        try await APIClient.shared.send(
            endpoint: "/v2/notifications/read-all",
            method: "PUT"
        )
    }

    func fetchPreferences() async throws -> [NotificationPreferenceDTO] {
        try await APIClient.shared.fetch(
            endpoint: "/v2/notifications/preferences",
            responseType: [NotificationPreferenceDTO].self
        )
    }

    func updatePreference(
        type: String,
        enabled: Bool
    ) async throws -> NotificationPreferenceDTO {
        try await APIClient.shared.put(
            endpoint: "/v2/notifications/preferences/\(type)",
            body: NotificationPreferenceUpdateDTO(enabled: enabled),
            responseType: NotificationPreferenceDTO.self
        )
    }
}
