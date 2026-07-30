import Foundation

enum ExcelBatchMode: String, Codable, CaseIterable, Identifiable {
    case distributed = "DISTRIBUTED"
    case centralized = "CENTRALIZED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .distributed:
            return "Por sucursal"
        case .centralized:
            return "Consolidado"
        }
    }
}

enum ExcelTemplateKind {
    case branchSales
    case centralizedSales
    case stock

    var endpointKey: String {
        switch self {
        case .branchSales: return "sales-branch"
        case .centralizedSales: return "sales-centralized"
        case .stock: return "stock"
        }
    }

    var filename: String {
        switch self {
        case .branchSales:
            return "Plantilla_Ventas_Sucursal.xlsx"
        case .centralizedSales:
            return "Plantilla_Ventas_Consolidada.xlsx"
        case .stock:
            return "Plantilla_Stock_Empresa.xlsx"
        }
    }

    var displayName: String {
        switch self {
        case .branchSales: return "Plantilla de ventas"
        case .centralizedSales: return "Ventas consolidadas"
        case .stock: return "Stock de la empresa"
        }
    }
}

struct ExcelBatchCreateRequestDTO: Encodable {
    let mode: ExcelBatchMode
    let periodFrom: String
    let periodTo: String
    let expectedBranchCodes: [String]?

    enum CodingKeys: String, CodingKey {
        case mode
        case periodFrom = "period_from"
        case periodTo = "period_to"
        case expectedBranchCodes = "expected_branch_codes"
    }
}

struct ExcelUploadDTO: Decodable, Identifiable {
    let id: Int
    let fileType: String
    let scopeKey: String
    let branchCode: String?
    let originalFilename: String
    let rowCount: Int
    let status: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case fileType = "file_type"
        case scopeKey = "scope_key"
        case branchCode = "branch_code"
        case originalFilename = "original_filename"
        case rowCount = "row_count"
        case status
        case updatedAt = "updated_at"
    }
}

struct ExcelBatchDTO: Decodable, Identifiable {
    let id: Int
    let publicID: String
    let mode: ExcelBatchMode
    let status: String
    let periodFrom: String
    let periodTo: String
    let expectedBranchCodes: [String]
    let uploadedBranchCodes: [String]
    let missingBranchCodes: [String]
    let hasStockSnapshot: Bool
    let stockSnapshotAt: String?
    let runID: Int?
    let errorSummary: String?
    let createdAt: String
    let completedAt: String?
    let updatedAt: String
    let uploads: [ExcelUploadDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case mode
        case status
        case periodFrom = "period_from"
        case periodTo = "period_to"
        case expectedBranchCodes = "expected_branch_codes"
        case uploadedBranchCodes = "uploaded_branch_codes"
        case missingBranchCodes = "missing_branch_codes"
        case hasStockSnapshot = "has_stock_snapshot"
        case stockSnapshotAt = "stock_snapshot_at"
        case runID = "run_id"
        case errorSummary = "error_summary"
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
        case uploads
    }

    var periodLabel: String {
        "\(periodFrom) → \(periodTo)"
    }
}

struct ExcelBatchAnalysisDTO: Decodable {
    let batch: ExcelBatchDTO
    let algorithmVersion: String
    let runID: Int

    enum CodingKeys: String, CodingKey {
        case batch
        case algorithmVersion = "algorithm_version"
        case runID = "run_id"
    }
}
