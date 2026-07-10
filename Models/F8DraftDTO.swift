import Foundation

struct F8DraftAPIResponseDTO: Decodable {

    let status: String
    let data: F8DraftDTO
}

struct F8DraftValidationAPIResponseDTO: Decodable {

    let status: String
    let data: F8DraftValidationDTO
}

struct F8DraftRowOptionsAPIResponseDTO: Decodable {

    let status: String
    let data: F8DraftRowOptionsDTO
}

struct F8DraftDTO: Decodable, Identifiable {

    let id: Int
    let executionID: Int
    let status: String
    let initialReport: String?
    let finalReport: String?
    let createdAt: String?
    let updatedAt: String?
    let confirmedAt: String?
    let rows: [F8DraftRowDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case executionID = "execution_id"
        case status
        case initialReport = "initial_report"
        case finalReport = "final_report"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case confirmedAt = "confirmed_at"
        case rows
    }

    var isConfirmed: Bool {
        status.uppercased() == "CONFIRMED"
    }

    var displayStatus: String {
        isConfirmed ? "Confirmado" : "Borrador"
    }

    var finalReportFileName: String? {

        guard let finalReport,
              !finalReport.isEmpty else {
            return nil
        }

        return URL(
            fileURLWithPath: finalReport
        ).lastPathComponent
    }
}

struct F8DraftRowDTO: Decodable, Identifiable {

    let id: Int
    let draftID: Int
    let rowOrder: Int
    let origin: String
    let brand: String
    let code: String
    let article: String
    let description: String
    let destination: String
    let size: String
    let quantity: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case draftID = "draft_id"
        case rowOrder = "row_order"
        case origin
        case brand
        case code
        case article
        case description
        case destination
        case size
        case quantity
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct F8DraftRowUpdateRequestDTO: Encodable {

    let origin: String
    let destination: String
    let size: String
    let quantity: Int
}

struct F8DraftValidationDTO: Decodable {

    let draftID: Int
    let canConfirm: Bool
    let rows: [F8DraftRowValidationDTO]

    enum CodingKeys: String, CodingKey {
        case draftID = "draft_id"
        case canConfirm = "can_confirm"
        case rows
    }
}

struct F8DraftRowValidationDTO: Decodable, Identifiable {

    let rowID: Int
    let isValid: Bool
    let message: String
    let maxQuantity: Int
    let availableQuantity: Int

    var id: Int {
        rowID
    }

    enum CodingKeys: String, CodingKey {
        case rowID = "row_id"
        case isValid = "is_valid"
        case message
        case maxQuantity = "max_quantity"
        case availableQuantity = "available_quantity"
    }
}

struct F8DraftRowOptionsDTO: Decodable {

    let draftID: Int
    let rowID: Int
    let origins: [F8OriginOptionDTO]
    let sizes: [String]
    let destinations: [String]
    let validation: F8DraftRowValidationDetailDTO

    enum CodingKeys: String, CodingKey {
        case draftID = "draft_id"
        case rowID = "row_id"
        case origins
        case sizes
        case destinations
        case validation
    }
}

struct F8OriginOptionDTO: Decodable, Identifiable {

    let origin: String
    let stockQuantity: Int
    let committedQuantity: Int
    let availableQuantity: Int

    var id: String {
        origin
    }

    enum CodingKeys: String, CodingKey {
        case origin
        case stockQuantity = "stock_quantity"
        case committedQuantity = "committed_quantity"
        case availableQuantity = "available_quantity"
    }
}

struct F8DraftRowValidationDetailDTO: Decodable {

    let isValid: Bool
    let message: String
    let maxQuantity: Int
    let availableQuantity: Int

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case message
        case maxQuantity = "max_quantity"
        case availableQuantity = "available_quantity"
    }
}

struct F8ServerErrorDTO: Decodable {

    let detail: String?
}