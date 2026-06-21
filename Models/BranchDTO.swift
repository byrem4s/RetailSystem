import Foundation

struct BranchesResponseDTO: Decodable {

    let summary: BranchesSummaryDTO
    let ranking: [BranchRankingDTO]
    let selectedBranch: SelectedBranchDTO?

    enum CodingKeys: String, CodingKey {
        case summary
        case ranking
        case selectedBranch = "selected_branch"
    }
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

struct BranchRankingDTO: Decodable, Identifiable {

    let id: String
    let branch: String
    let subtitle: String
    let health: Int

    let critical: Int
    let high: Int
    let medium: Int
    let totalCases: Int

    enum CodingKeys: String, CodingKey {
        case id
        case branch
        case subtitle
        case health
        case critical
        case high
        case medium
        case totalCases = "total_cases"
    }
}

struct SelectedBranchDTO: Decodable, Identifiable {

    let id: String
    let branch: String
    let subtitle: String
    let health: Int
    let riskLevel: String

    let critical: Int
    let high: Int
    let medium: Int
    let totalCases: Int

    let riskProducts: [BranchRiskProductDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case branch
        case subtitle
        case health
        case riskLevel = "risk_level"
        case critical
        case high
        case medium
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