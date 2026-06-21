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

    enum CodingKeys: String, CodingKey {
        case movements
        case completedReplenishments = "completed_replenishments"
        case partialReplenishments = "partial_replenishments"
        case withoutReplenishment = "without_replenishment"
    }
}

struct HomeRisksDTO: Decodable {

    let critical: Int
    let high: Int
    let medium: Int
}

struct HomeRecentActivityDTO: Decodable, Identifiable {

    let id = UUID()

    let title: String
    let branch: String
    let priority: String
    let reason: String
    let suggested: Int

    enum CodingKeys: String, CodingKey {
        case title
        case branch
        case priority
        case reason
        case suggested
    }
}