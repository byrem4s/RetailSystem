import Foundation

struct BranchesResponseDTO: Decodable {

    let summary: BranchesSummaryDTO
    let ranking: [BranchRankingDTO]
}

struct BranchesSummaryDTO: Decodable {

    let branches: Int
    let averageHealth: Int
    let highRisk: Int
    let movements: Int

    enum CodingKeys: String, CodingKey {
        case branches
        case averageHealth = "average_health"
        case highRisk = "high_risk"
        case movements
    }
}

struct BranchIssuesDTO: Decodable {

    let breakRisk: Int
    let noRotation: Int
    let overstock: Int
    let incompleteCurve: Int

    enum CodingKeys: String, CodingKey {
        case breakRisk = "break_risk"
        case noRotation = "no_rotation"
        case overstock
        case incompleteCurve = "incomplete_curve"
    }
}

struct BranchRankingDTO: Decodable, Identifiable {

    let id: String
    let branch: String
    let subtitle: String
    let health: Int
    let riskLevel: String
    let issues: BranchIssuesDTO
    let totalCases: Int

    enum CodingKeys: String, CodingKey {
        case id
        case branch
        case subtitle
        case health
        case riskLevel = "risk_level"
        case issues
        case totalCases = "total_cases"
    }
}

struct BranchDetailDTO: Decodable, Identifiable {

    let id: String
    let branch: String
    let subtitle: String
    let health: Int
    let riskLevel: String
    let issues: BranchIssuesDTO
    let totalCases: Int
    let riskProducts: [BranchRiskProductDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case branch
        case subtitle
        case health
        case riskLevel = "risk_level"
        case issues
        case totalCases = "total_cases"
        case riskProducts = "risk_products"
    }
}

struct BranchRiskProductDTO: Decodable, Identifiable {

    let id: String
    let name: String
    let status: String
    let stock: Int
    let needed: Int
    let priority: String
}