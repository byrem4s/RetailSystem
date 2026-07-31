import Foundation

struct IntelligenceBatchDTO: Decodable {
    let id: Int
    let periodFrom: String
    let periodTo: String
    let mode: String
    let distributed: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case periodFrom = "period_from"
        case periodTo = "period_to"
        case mode
        case distributed
    }
}

struct IntelligenceMetricsDTO: Decodable {
    let healthScore: Int
    let healthStatus: String
    let needs: Int
    let neededUnits: Int
    let allocatedUnits: Int
    let unresolvedUnits: Int
    let completeProducts: Int
    let partialProducts: Int
    let unfilledProducts: Int
    let outletConflicts: Int

    enum CodingKeys: String, CodingKey {
        case healthScore = "health_score"
        case healthStatus = "health_status"
        case needs
        case neededUnits = "needed_units"
        case allocatedUnits = "allocated_units"
        case unresolvedUnits = "unresolved_units"
        case completeProducts = "complete_products"
        case partialProducts = "partial_products"
        case unfilledProducts = "unfilled_products"
        case outletConflicts = "outlet_conflicts"
    }
}

struct IntelligenceTrendPointDTO: Decodable, Identifiable {
    let batchID: Int
    let periodTo: String
    let healthScore: Int

    var id: Int { batchID }

    enum CodingKeys: String, CodingKey {
        case batchID = "batch_id"
        case periodTo = "period_to"
        case healthScore = "health_score"
    }
}

struct BranchHealthDTO: Decodable, Identifiable {
    let branchID: Int
    let branchCode: String
    let branchName: String
    let isOutlet: Bool
    let healthScore: Int
    let healthStatus: String
    let previousHealthScore: Int?
    let trendDelta: Int?
    let needs: Int
    let neededUnits: Int
    let allocatedUnits: Int
    let unresolvedUnits: Int
    let completeProducts: Int
    let partialProducts: Int
    let unfilledProducts: Int
    let outletConflicts: Int

    var id: Int { branchID }

    enum CodingKeys: String, CodingKey {
        case branchID = "branch_id"
        case branchCode = "branch_code"
        case branchName = "branch_name"
        case isOutlet = "is_outlet"
        case healthScore = "health_score"
        case healthStatus = "health_status"
        case previousHealthScore = "previous_health_score"
        case trendDelta = "trend_delta"
        case needs
        case neededUnits = "needed_units"
        case allocatedUnits = "allocated_units"
        case unresolvedUnits = "unresolved_units"
        case completeProducts = "complete_products"
        case partialProducts = "partial_products"
        case unfilledProducts = "unfilled_products"
        case outletConflicts = "outlet_conflicts"
    }
}

struct ProductAlertDTO: Decodable, Identifiable {
    let key: String
    let severity: String
    let branchCode: String
    let branchName: String
    let sku: String
    let size: String
    let description: String?
    let brand: String?
    let category: String?
    let currentStock: Int
    let targetStock: Int
    let neededQuantity: Int
    let allocatedQuantity: Int
    let residualQuantity: Int
    let fulfillmentStatus: String
    let reasonCode: String
    let reason: String
    let recommendation: String
    let productSegment: String?
    let evidence: [String]

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, severity, sku, size, description, brand, category, evidence
        case branchCode = "branch_code"
        case branchName = "branch_name"
        case currentStock = "current_stock"
        case targetStock = "target_stock"
        case neededQuantity = "needed_quantity"
        case allocatedQuantity = "allocated_quantity"
        case residualQuantity = "residual_quantity"
        case fulfillmentStatus = "fulfillment_status"
        case reasonCode = "reason_code"
        case reason
        case recommendation
        case productSegment = "product_segment"
    }
}

struct IntelligenceDashboardDTO: Decodable {
    let scope: String
    let batch: IntelligenceBatchDTO?
    let metrics: IntelligenceMetricsDTO
    let previousHealthScore: Int?
    let trendDelta: Int?
    let trend: [IntelligenceTrendPointDTO]
    let branches: [BranchHealthDTO]
    let alerts: [ProductAlertDTO]

    enum CodingKeys: String, CodingKey {
        case scope, batch, metrics, trend, branches, alerts
        case previousHealthScore = "previous_health_score"
        case trendDelta = "trend_delta"
    }
}

