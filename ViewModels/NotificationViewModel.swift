import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published private(set) var notifications: [NotificationDTO] = []
    @Published private(set) var unreadCount = 0
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service = NotificationService()

    func loadNotifications() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notifications = try await service.fetchNotifications()
            unreadCount = notifications.filter { !$0.isRead }.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadUnreadCount() async {
        do {
            unreadCount = try await service.fetchUnreadCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(_ notification: NotificationDTO) async {
        guard !notification.isRead else { return }
        do {
            let updated = try await service.markAsRead(
                notificationID: notification.id
            )
            if let index = notifications.firstIndex(
                where: { $0.id == updated.id }
            ) {
                notifications[index] = updated
            }
            unreadCount = max(unreadCount - 1, 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        do {
            try await service.markAllAsRead()
            await loadNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
