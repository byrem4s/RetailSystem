import Foundation

struct ActivityResponseDTO: Decodable {

    let summary: ActivitySummaryDTO
    let activities: [ActivityDTO]
}

struct ActivitySummaryDTO: Decodable {

    let total: Int
    let completed: Int
    let failed: Int
    let warnings: Int

    let pipelineEvents: Int
    let f8Events: Int
    let reportEvents: Int

    enum CodingKeys: String, CodingKey {
        case total
        case completed
        case failed
        case warnings
        case pipelineEvents = "pipeline_events"
        case f8Events = "f8_events"
        case reportEvents = "report_events"
    }
}

struct ActivityDTO: Decodable, Identifiable {

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