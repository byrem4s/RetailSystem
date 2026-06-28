import Foundation

struct NotificationsAPIResponseDTO: Decodable {

    let status: String
    let data: NotificationsResponseDTO
}

struct NotificationUnreadCountAPIResponseDTO: Decodable {

    let status: String
    let data: NotificationUnreadCountDTO
}

struct NotificationReadAPIResponseDTO: Decodable {

    let status: String
    let data: NotificationDTO
}

struct MarkAllNotificationsReadAPIResponseDTO: Decodable {

    let status: String
    let data: MarkAllNotificationsReadDTO
}

struct NotificationsResponseDTO: Decodable {

    let summary: NotificationsSummaryDTO
    let notifications: [NotificationDTO]
}

struct NotificationsSummaryDTO: Decodable {

    let total: Int
    let unread: Int
    let critical: Int
    let warnings: Int
    let info: Int
}

struct NotificationDTO: Decodable, Identifiable {

    let id: Int

    let notificationType: String

    let title: String
    let message: String?

    let severity: String
    let source: String

    let isRead: Bool
    let readAt: String?

    let executionID: Int?
    let draftID: Int?
    let riskKey: String?

    let actionURL: String?

    let createdAt: String
    let time: String

    enum CodingKeys: String, CodingKey {
        case id
        case notificationType = "notification_type"
        case title
        case message
        case severity
        case source
        case isRead = "is_read"
        case readAt = "read_at"
        case executionID = "execution_id"
        case draftID = "draft_id"
        case riskKey = "risk_key"
        case actionURL = "action_url"
        case createdAt = "created_at"
        case time
    }
}

struct NotificationUnreadCountDTO: Decodable {

    let unread: Int
}

struct MarkAllNotificationsReadDTO: Decodable {

    let updated: Int
}