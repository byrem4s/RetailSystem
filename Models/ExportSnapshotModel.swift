import Foundation


struct ExportSnapshotModel:
Decodable, Identifiable {

    let id = UUID()

    let analysisReport: String

    let transferReport: String

    let createdAt: String

    enum CodingKeys: String, CodingKey {

        case analysisReport =
        "analysis_report"

        case transferReport =
        "transfer_report"

        case createdAt =
        "created_at"
    }
}