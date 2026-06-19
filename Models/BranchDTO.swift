import Foundation

struct BranchDTO: Decodable, Identifiable {

    let id = UUID()

    let branch: String

    let health: Int

    let critical: Int

    let high: Int

    let medium: Int

    let totalCases: Int

    enum CodingKeys: String, CodingKey {

        case branch

        case health

        case critical

        case high

        case medium

        case totalCases = "total_cases"
    }
}