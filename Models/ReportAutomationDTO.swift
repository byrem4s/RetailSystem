import Foundation

struct ReportAutomationConfigAPIResponseDTO: Decodable {

    let status: String
    let data: ReportAutomationConfigDTO
}

struct ReportAutomationRunNowAPIResponseDTO: Decodable {

    let status: String
    let data: ReportAutomationRunNowDTO
}

struct ReportAutomationRunsAPIResponseDTO: Decodable {

    let status: String
    let data: ReportAutomationRunsResponseDTO
}

struct ReportAutomationConfigDTO: Decodable {

    let id: Int

    let enabled: Bool
    let frequency: String
    let hour: Int
    let minute: Int
    let weekday: Int?

    let lastRunAt: String?
    let nextRunAt: String?

    let scheduleLabel: String

    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case enabled
        case frequency
        case hour
        case minute
        case weekday
        case lastRunAt = "last_run_at"
        case nextRunAt = "next_run_at"
        case scheduleLabel = "schedule_label"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ReportAutomationConfigUpdateDTO: Encodable {

    let enabled: Bool?
    let frequency: String?
    let hour: Int?
    let minute: Int?
    let weekday: Int?
}

struct ReportAutomationRunNowDTO: Decodable {

    let run: ReportAutomationRunDTO
}

struct ReportAutomationRunsResponseDTO: Decodable {

    let runs: [ReportAutomationRunDTO]
}

struct ReportAutomationRunDTO: Decodable, Identifiable {

    let id: Int
    let executionID: Int?

    let status: String
    let message: String?

    let startedAt: String
    let finishedAt: String?
    let durationSeconds: Double?

    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case executionID = "execution_id"
        case status
        case message
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case durationSeconds = "duration_seconds"
        case createdAt = "created_at"
    }
}