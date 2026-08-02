import Foundation

struct TransferV2DTO: Decodable, Identifiable {
    let id: Int
    let publicID: String
    let recommendationID: Int?
    let originBranchID: Int
    let originBranch: String
    let destinationBranchID: Int
    let destinationBranch: String
    let sku: String
    let size: String
    let transferType: String
    let status: String
    let fulfillmentStatus: String
    let neededQuantity: Int
    let requestedQuantity: Int
    let approvedQuantity: Int?
    let dispatchedQuantity: Int?
    let receivedQuantity: Int?
    let rejectionReason: String?
    let discrepancyNote: String?
    let requestNote: String?
    let estimatedDeliveryDate: String?
    let version: Int
    let createdAt: String
    let approvedAt: String?
    let dispatchedAt: String?
    let completedAt: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case recommendationID = "recommendation_id"
        case originBranchID = "origin_branch_id"
        case originBranch = "origin_branch"
        case destinationBranchID = "destination_branch_id"
        case destinationBranch = "destination_branch"
        case sku
        case size
        case transferType = "transfer_type"
        case status
        case fulfillmentStatus = "fulfillment_status"
        case neededQuantity = "needed_quantity"
        case requestedQuantity = "requested_quantity"
        case approvedQuantity = "approved_quantity"
        case dispatchedQuantity = "dispatched_quantity"
        case receivedQuantity = "received_quantity"
        case rejectionReason = "rejection_reason"
        case discrepancyNote = "discrepancy_note"
        case requestNote = "request_note"
        case estimatedDeliveryDate = "estimated_delivery_date"
        case version
        case createdAt = "created_at"
        case approvedAt = "approved_at"
        case dispatchedAt = "dispatched_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }

    var operationalQuantity: Int {
        dispatchedQuantity
        ?? approvedQuantity
        ?? requestedQuantity
    }

    var displayStatus: String {
        switch status {
        case "REQUESTED": return "Esperando aprobación"
        case "RECOMMENDED": return "Recomendada"
        case "APPROVED": return "Aprobada"
        case "PREPARING": return "En preparación"
        case "DISPATCHED": return "Despachada"
        case "PARTIALLY_RECEIVED": return "Recepción parcial"
        case "COMPLETED": return "Completada"
        case "REJECTED": return "Rechazada"
        default: return status
        }
    }
}

struct CustomerRequestOptionDTO: Decodable, Identifiable, Hashable {
    let originBranchID: Int
    let originBranch: String
    let sku: String
    let size: String
    let description: String?
    let brand: String?
    let category: String?
    let availableQuantity: Int

    var id: String { "\(originBranchID)|\(sku)|\(size)" }

    enum CodingKeys: String, CodingKey {
        case sku, size, description, brand, category
        case originBranchID = "origin_branch_id"
        case originBranch = "origin_branch"
        case availableQuantity = "available_quantity"
    }
}

struct CustomerRequestCreateDTO: Encodable {
    let originBranchID: Int
    let destinationBranchID: Int?
    let sku: String
    let size: String
    let quantity: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case sku, size, quantity, note
        case originBranchID = "origin_branch_id"
        case destinationBranchID = "destination_branch_id"
    }
}

struct VersionedTransferRequestDTO: Encodable {
    let version: Int
}

struct TransferQuantityRequestDTO: Encodable {
    let version: Int
    let quantity: Int
}

struct TransferRejectRequestDTO: Encodable {
    let version: Int
    let reason: String
}

struct TransferReceiveRequestDTO: Encodable {
    let version: Int
    let receivedQuantity: Int
    let discrepancyNote: String?

    enum CodingKeys: String, CodingKey {
        case version
        case receivedQuantity = "received_quantity"
        case discrepancyNote = "discrepancy_note"
    }
}
