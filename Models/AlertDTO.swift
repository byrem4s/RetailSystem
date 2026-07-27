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
    let riskKey: String?

    let priority: String
    let type: String
    let title: String
    let branch: String

    let productCode: String?
    let size: String?

    let sold: Int
    let soldPeriodDays: Int
    let stock: Int
    let averageVelocity: Double
    let needed: Int
    let residualNeed: Int?
    let replenished: Int?
    let riskDays: Int

    let reason: String
    let createdAt: String

    var resolvedRiskKey: String {
        riskKey ?? id
    }

    var pendingQuantity: Int {

        if let residualNeed {
            return max(residualNeed, 0)
        }

        if let replenished {
            return max(needed - replenished, 0)
        }

        return max(needed, 0)
    }

    var replenishedQuantity: Int {

        if let replenished {
            return max(replenished, 0)
        }

        return max(needed - pendingQuantity, 0)
    }

    var isUnresolved: Bool {
        pendingQuantity > 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case riskKey = "risk_key"
        case priority
        case type
        case title
        case branch
        case productCode = "product_code"
        case size
        case sold
        case soldPeriodDays = "sold_period_days"
        case stock
        case averageVelocity = "average_velocity"
        case needed
        case residualNeed = "residual_need"
        case replenished
        case riskDays = "risk_days"
        case reason
        case createdAt = "created_at"
    }
}
