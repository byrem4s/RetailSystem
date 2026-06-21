import Foundation

struct ReportsResponseDTO: Decodable {

    let latest: ReportDTO?
    let history: [ReportDTO]
    let configuration: ReportsConfigurationDTO
}

struct ReportDTO: Decodable, Identifiable {

    let id: String
    let fileName: String
    let createdAt: String
    let type: String
    let rows: String
    let sheets: String
    let size: String
    let status: String
    let filePath: String

    enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
        case createdAt = "created_at"
        case type
        case rows
        case sheets
        case size
        case status
        case filePath = "file_path"
    }
}

struct ReportsConfigurationDTO: Decodable {

    let schedule: String
    let notifications: Bool
}