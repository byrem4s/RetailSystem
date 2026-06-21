import Foundation

struct AlertsResponseDTO: Decodable {

    let summary: AlertSummaryDTO
    let alerts: [AlertDTO]
}

struct AlertSummaryDTO: Decodable {

    let critical: Int
    let high: Int
    let medium: Int
    let total: Int
}

struct AlertDTO: Decodable, Identifiable {

    let id: String
    let priority: String
    let type: String
    let title: String
    let branch: String

    let sold: Int
    let soldPeriodDays: Int
    let stock: Int
    let averageVelocity: Double
    let needed: Int
    let riskDays: Int

    let reason: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case priority
        case type
        case title
        case branch
        case sold
        case soldPeriodDays = "sold_period_days"
        case stock
        case averageVelocity = "average_velocity"
        case needed
        case riskDays = "risk_days"
        case reason
        case createdAt = "created_at"
    }
}