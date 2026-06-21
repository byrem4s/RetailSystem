import Foundation

struct ActivityResponseDTO: Decodable {

    let summary: ActivitySummaryDTO
    let activities: [ActivityDTO]
}

struct ActivitySummaryDTO: Decodable {

    let movements: Int
    let completed: Int
    let partial: Int
    let withoutReplenishment: Int

    enum CodingKeys: String, CodingKey {
        case movements
        case completed
        case partial
        case withoutReplenishment = "without_replenishment"
    }
}

struct ActivityDTO: Decodable, Identifiable {

    let id: String

    let type: String
    let status: String

    let title: String
    let product: String
    let size: String

    let origin: String
    let destination: String
    let branch: String

    let priority: String
    let reason: String

    let suggested: Int
    let time: String
    let actionTaken: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case title
        case product
        case size
        case origin
        case destination
        case branch
        case priority
        case reason
        case suggested
        case time
        case actionTaken = "action_taken"
    }
}