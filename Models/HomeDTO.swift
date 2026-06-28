import Foundation

struct HomeDTO: Decodable {

    let user: HomeUserDTO
    let summary: HomeSummaryDTO
    let risks: HomeRisksDTO
    let recentActivity: [HomeRecentActivityDTO]

    enum CodingKeys: String, CodingKey {
        case user
        case summary
        case risks
        case recentActivity = "recent_activity"
    }
}

struct HomeUserDTO: Decodable {

    let name: String
    let branch: String
}

struct HomeSummaryDTO: Decodable {

    let movements: Int
    let completedReplenishments: Int
    let partialReplenishments: Int
    let withoutReplenishment: Int

    let suggestedUnits: Int?
    let coveredUnits: Int?
    let pendingUnits: Int?
    let coverageRate: Int?
    let detectedCases: Int?
    let branchesWithRisk: Int?
    let lastUpdate: String?

    enum CodingKeys: String, CodingKey {
        case movements
        case completedReplenishments = "completed_replenishments"
        case partialReplenishments = "partial_replenishments"
        case withoutReplenishment = "without_replenishment"

        case suggestedUnits = "suggested_units"
        case coveredUnits = "covered_units"
        case pendingUnits = "pending_units"
        case coverageRate = "coverage_rate"
        case detectedCases = "detected_cases"
        case branchesWithRisk = "branches_with_risk"
        case lastUpdate = "last_update"
    }
}

struct HomeRisksDTO: Decodable {

    let critical: Int
    let high: Int
    let medium: Int
}

struct HomeRecentActivityDTO: Decodable, Identifiable {

    let id: String

    let eventType: String
    let status: String
    let severity: String
    let source: String

    let title: String
    let description: String

    let executionID: Int?
    let draftID: Int?
    let rowID: Int?

    let createdAt: String
    let time: String

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case status
        case severity
        case source
        case title
        case description
        case executionID = "execution_id"
        case draftID = "draft_id"
        case rowID = "row_id"
        case createdAt = "created_at"
        case time
    }
}