import Foundation

struct RiskDetailAPIResponseDTO: Decodable {

    let status: String
    let data: RiskDetailDTO
}

struct RiskDetailDTO: Decodable, Identifiable {

    var id: String {
        current.riskKey
    }

    let current: RiskDetailCurrentDTO
    let history: [RiskDetailHistoryPointDTO]
    let comparison: RiskDetailComparisonDTO?
    let recommendation: RiskDetailRecommendationDTO?
}

struct RiskDetailCurrentDTO: Decodable {

    let riskKey: String
    let branchID: String?
    let branch: String
    let productCode: String
    let size: String
    let priority: String
    let riskType: String

    let sold: Int
    let stock: Int
    let needed: Int
    let residualNeed: Int

    let averageVelocity: Double
    let coverageDays: Double?

    let reason: String?

    enum CodingKeys: String, CodingKey {
        case riskKey = "risk_key"
        case branchID = "branch_id"
        case branch
        case productCode = "product_code"
        case size
        case priority
        case riskType = "risk_type"
        case sold
        case stock
        case needed
        case residualNeed = "residual_need"
        case averageVelocity = "average_velocity"
        case coverageDays = "coverage_days"
        case reason
    }
}

struct RiskDetailHistoryPointDTO: Decodable, Identifiable {

    var id: String {
        "\(executionID)-\(createdAt)"
    }

    let executionID: Int
    let createdAt: String

    let priority: String
    let sold: Int
    let stock: Int
    let needed: Int
    let residualNeed: Int
    let averageVelocity: Double
    let coverageDays: Double?

    enum CodingKeys: String, CodingKey {
        case executionID = "execution_id"
        case createdAt = "created_at"
        case priority
        case sold
        case stock
        case needed
        case residualNeed = "residual_need"
        case averageVelocity = "average_velocity"
        case coverageDays = "coverage_days"
    }
}

struct RiskDetailComparisonDTO: Decodable {

    let currentExecutionID: Int?
    let previousExecutionID: Int?

    let currentPriority: String?
    let previousPriority: String?

    let currentNeeded: Int?
    let previousNeeded: Int?

    let currentStock: Int?
    let previousStock: Int?

    let currentResidualNeed: Int?
    let previousResidualNeed: Int?

    let trend: String
    let impact: String

    enum CodingKeys: String, CodingKey {
        case currentExecutionID = "current_execution_id"
        case previousExecutionID = "previous_execution_id"
        case currentPriority = "current_priority"
        case previousPriority = "previous_priority"
        case currentNeeded = "current_needed"
        case previousNeeded = "previous_needed"
        case currentStock = "current_stock"
        case previousStock = "previous_stock"
        case currentResidualNeed = "current_residual_need"
        case previousResidualNeed = "previous_residual_need"
        case trend
        case impact
    }
}

struct RiskDetailRecommendationDTO: Decodable {

    let title: String
    let reason: String
    let confidence: String

    let suggestedOrigin: String
    let suggestedDestination: String
    let suggestedQuantity: Int

    let canAddToF8: Bool
    let draftID: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case reason
        case confidence
        case suggestedOrigin = "suggested_origin"
        case suggestedDestination = "suggested_destination"
        case suggestedQuantity = "suggested_quantity"
        case canAddToF8 = "can_add_to_f8"
        case draftID = "draft_id"
    }
}

struct RiskActionStatusResponseDTO: Decodable {

    let status: String
}

struct EmptyBodyDTO: Encodable {}