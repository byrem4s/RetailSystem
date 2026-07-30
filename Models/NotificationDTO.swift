import Foundation

struct NotificationDTO: Decodable, Identifiable {
    let id: Int
    let notificationType: String
    let title: String
    let message: String
    let severity: String
    let batchID: Int?
    let transferID: Int?
    let isRead: Bool
    let readAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case notificationType = "notification_type"
        case title
        case message
        case severity
        case batchID = "batch_id"
        case transferID = "transfer_id"
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

struct NotificationUnreadCountDTO: Decodable {
    let count: Int
}
