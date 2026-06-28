import Foundation
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {

    @Published var response: NotificationsResponseDTO?
    @Published var unreadCount = 0

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = NotificationService()

    var notifications: [NotificationDTO] {
        response?.notifications ?? []
    }

    var summary: NotificationsSummaryDTO? {
        response?.summary
    }

    func loadNotifications() async {

        isLoading = true
        errorMessage = nil

        do {

            response = try await service.fetchNotifications()
            unreadCount = response?.summary.unread ?? 0

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadUnreadCount() async {

        do {

            unreadCount = try await service.fetchUnreadCount()

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(
        _ notification: NotificationDTO
    ) async {

        guard !notification.isRead else {
            return
        }

        do {

            _ = try await service.markAsRead(
                notificationID: notification.id
            )

            await loadNotifications()

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    func markAllAsRead() async {

        do {

            _ = try await service.markAllAsRead()

            await loadNotifications()

        } catch {

            errorMessage = error.localizedDescription
        }
    }
}