import Foundation

@MainActor
final class TransfersV2ViewModel: ObservableObject {

    @Published private(set) var transfers: [TransferV2DTO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var workingTransferID: Int?
    @Published var errorMessage: String?
    @Published private(set) var customerRequestOptions: [CustomerRequestOptionDTO] = []

    private let service = TransferV2Service()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            transfers = try await service.fetchTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCustomerRequestOptions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            customerRequestOptions = try await service.fetchCustomerRequestOptions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCustomerRequest(
        option: CustomerRequestOptionDTO,
        destinationBranchID: Int?,
        quantity: Int,
        note: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let created = try await service.createCustomerRequest(
                option: option,
                destinationBranchID: destinationBranchID,
                quantity: quantity,
                note: note
            )
            transfers.insert(created, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func approve(_ transfer: TransferV2DTO) async {
        await perform(transfer) {
            try await service.approve(transfer: transfer)
        }
    }

    func prepare(_ transfer: TransferV2DTO) async {
        await perform(transfer) {
            try await service.prepare(transfer: transfer)
        }
    }

    func dispatch(_ transfer: TransferV2DTO) async {
        await perform(transfer) {
            try await service.dispatch(transfer: transfer)
        }
    }

    func receive(_ transfer: TransferV2DTO) async {
        await perform(transfer) {
            try await service.receiveComplete(transfer: transfer)
        }
    }

    func reject(
        _ transfer: TransferV2DTO,
        reason: String
    ) async {
        await perform(transfer) {
            try await service.reject(
                transfer: transfer,
                reason: reason
            )
        }
    }

    func updateQuantity(
        _ transfer: TransferV2DTO,
        quantity: Int
    ) async {
        await perform(transfer) {
            try await service.updateQuantity(
                transfer: transfer,
                quantity: quantity
            )
        }
    }

    private func perform(
        _ transfer: TransferV2DTO,
        operation: () async throws -> TransferV2DTO
    ) async {
        workingTransferID = transfer.id
        errorMessage = nil
        defer {
            workingTransferID = nil
        }
        do {
            let updated = try await operation()
            if let index = transfers.firstIndex(
                where: { $0.id == updated.id }
            ) {
                transfers[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
