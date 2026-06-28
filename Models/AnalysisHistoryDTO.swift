import Foundation

struct AnalysisHistoryAPIResponseDTO: Decodable {

    let status: String
    let data: AnalysisHistoryResponseDTO
}

struct AnalysisHistoryResponseDTO: Decodable {

    let summary: AnalysisHistorySummaryDTO
    let days: [AnalysisHistoryDayDTO]
}

struct AnalysisHistorySummaryDTO: Decodable {

    let total: Int
    let completed: Int
    let failed: Int
    let days: Int
}

struct AnalysisHistoryDayDTO: Decodable, Identifiable {

    var id: String {
        date
    }

    let date: String
    let total: Int
    let completed: Int
    let failed: Int

    let analyses: [AnalysisHistoryItemDTO]
}

struct AnalysisHistoryItemDTO: Decodable, Identifiable {

    var id: Int {
        executionID
    }

    let executionID: Int

    let status: String
    let message: String?

    let createdAt: String
    let finishedAt: String?
    let durationSeconds: Double?

    let date: String
    let time: String

    let movements: Int
    let detectedCases: Int
    let branchesWithRisk: Int
    let coverageRate: Int?

    let critical: Int
    let high: Int
    let medium: Int

    let reports: AnalysisHistoryReportDTO?

    enum CodingKeys: String, CodingKey {
        case executionID = "execution_id"
        case status
        case message
        case createdAt = "created_at"
        case finishedAt = "finished_at"
        case durationSeconds = "duration_seconds"
        case date
        case time
        case movements
        case detectedCases = "detected_cases"
        case branchesWithRisk = "branches_with_risk"
        case coverageRate = "coverage_rate"
        case critical
        case high
        case medium
        case reports
    }
}

struct AnalysisHistoryReportDTO: Decodable {

    let analysisReport: String?
    let transferReport: String?

    let analysisFileName: String?
    let transferFileName: String?

    enum CodingKeys: String, CodingKey {
        case analysisReport = "analysis_report"
        case transferReport = "transfer_report"
        case analysisFileName = "analysis_file_name"
        case transferFileName = "transfer_file_name"
    }
}