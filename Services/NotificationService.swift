import Foundation

final class NotificationService {

    func fetchNotifications(
        unreadOnly: Bool = false
    ) async throws -> NotificationsResponseDTO {

        var endpoint = "/notifications"

        if unreadOnly {
            endpoint += "?unread_only=true"
        }

        let response = try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: NotificationsAPIResponseDTO.self
        )

        return response.data
    }

    func fetchUnreadCount() async throws -> Int {

        let response = try await APIClient.shared.fetch(
            endpoint: "/notifications/unread-count",
            responseType: NotificationUnreadCountAPIResponseDTO.self
        )

        return response.data.unread
    }

    func markAsRead(
        notificationID: Int
    ) async throws -> NotificationDTO {

        let response = try await APIClient.shared.put(
            endpoint: "/notifications/\(notificationID)/read",
            responseType: NotificationReadAPIResponseDTO.self
        )

        return response.data
    }

    func markAllAsRead() async throws -> Int {

        let response = try await APIClient.shared.put(
            endpoint: "/notifications/read-all",
            responseType: MarkAllNotificationsReadAPIResponseDTO.self
        )

        return response.data.updated
    }
}