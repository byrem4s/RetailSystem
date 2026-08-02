import Foundation

final class TransferV2Service {

    private let client = APIClient.shared

    func fetchTransfers() async throws -> [TransferV2DTO] {
        try await client.fetch(
            endpoint: "/v2/transfers",
            responseType: [TransferV2DTO].self
        )
    }

    func fetchCustomerRequestOptions() async throws -> [CustomerRequestOptionDTO] {
        try await client.fetch(
            endpoint: "/v2/customer-requests/options",
            responseType: [CustomerRequestOptionDTO].self
        )
    }

    func createCustomerRequest(
        option: CustomerRequestOptionDTO,
        destinationBranchID: Int?,
        quantity: Int,
        note: String?
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/customer-requests",
            body: CustomerRequestCreateDTO(
                originBranchID: option.originBranchID,
                destinationBranchID: destinationBranchID,
                sku: option.sku,
                size: option.size,
                quantity: quantity,
                note: note
            ),
            responseType: TransferV2DTO.self
        )
    }

    func approve(
        transfer: TransferV2DTO
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/approve",
            body: VersionedTransferRequestDTO(
                version: transfer.version
            ),
            responseType: TransferV2DTO.self
        )
    }

    func updateQuantity(
        transfer: TransferV2DTO,
        quantity: Int
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/quantity",
            body: TransferQuantityRequestDTO(
                version: transfer.version,
                quantity: quantity
            ),
            responseType: TransferV2DTO.self
        )
    }

    func prepare(
        transfer: TransferV2DTO
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/prepare",
            body: VersionedTransferRequestDTO(
                version: transfer.version
            ),
            responseType: TransferV2DTO.self
        )
    }

    func dispatch(
        transfer: TransferV2DTO
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/dispatch",
            body: VersionedTransferRequestDTO(
                version: transfer.version
            ),
            responseType: TransferV2DTO.self
        )
    }

    func reject(
        transfer: TransferV2DTO,
        reason: String
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/reject",
            body: TransferRejectRequestDTO(
                version: transfer.version,
                reason: reason
            ),
            responseType: TransferV2DTO.self
        )
    }

    func receiveComplete(
        transfer: TransferV2DTO
    ) async throws -> TransferV2DTO {
        try await client.post(
            endpoint: "/v2/transfers/\(transfer.id)/receive",
            body: TransferReceiveRequestDTO(
                version: transfer.version,
                receivedQuantity: transfer.dispatchedQuantity ?? 0,
                discrepancyNote: nil
            ),
            responseType: TransferV2DTO.self
        )
    }
}
