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
    let sheets: String
    let size: String
    let status: String
    let filePath: String
    let downloadURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
        case createdAt = "created_at"
        case type
        case sheets
        case size
        case status
        case filePath = "file_path"
        case downloadURL = "download_url"
    }
}

struct ReportsConfigurationDTO: Decodable {

    let schedule: String
    let notifications: Bool
}