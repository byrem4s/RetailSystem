import Foundation

@MainActor
final class F8EditorViewModel: ObservableObject {
    @Published private(set) var rows: [F8RecommendationRowDTO] = []
    @Published private(set) var editable = false
    @Published var quantities: [Int: Int] = [:]
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?
    @Published private(set) var savedRowIDs: Set<Int> = []
    @Published private(set) var manualOptions: F8ManualOptionsDTO?

    let batchID: Int
    private let service = ExcelBatchService()

    init(batchID: Int) {
        self.batchID = batchID
    }

    func load() async {
        await perform {
            apply(try await service.fetchRecommendations(batchID: batchID))
            manualOptions = try await service.fetchManualOptions(
                batchID: batchID
            )
        }
    }

    func quantityChanged(for rowID: Int) {
        savedRowIDs.remove(rowID)
    }

    func save(_ row: F8RecommendationRowDTO) async {
        let quantity = quantities[row.id] ?? row.quantity
        guard quantity != row.quantity else { return }
        await perform {
            apply(
                try await service.updateRecommendation(
                    batchID: batchID,
                    recommendationID: row.id,
                    quantity: quantity
                )
            )
            noticeMessage = "Cantidad actualizada y análisis recalculado."
            savedRowIDs.insert(row.id)
        }
    }

    func addManualRow(
        variant: F8ManualVariantDTO,
        destination: F8ManualBranchDTO,
        quantity: Int
    ) async -> Bool {
        var succeeded = false
        await perform {
            apply(
                try await service.addRecommendation(
                    batchID: batchID,
                    request: F8RecommendationCreateDTO(
                        origin: variant.origin,
                        destination: destination.code,
                        sku: variant.sku,
                        size: variant.size,
                        quantity: quantity
                    )
                )
            )
            manualOptions = try await service.fetchManualOptions(
                batchID: batchID
            )
            noticeMessage = "Movimiento manual validado y agregado."
            succeeded = true
        }
        return succeeded
    }

    func remove(_ row: F8RecommendationRowDTO) async {
        await perform {
            apply(
                try await service.deleteRecommendation(
                    batchID: batchID,
                    recommendationID: row.id
                )
            )
            noticeMessage = "Movimiento eliminado del F8."
        }
    }

    private func apply(_ result: F8RecommendationListDTO) {
        rows = result.rows
        editable = result.editable
        quantities = Dictionary(
            uniqueKeysWithValues: result.rows.map { ($0.id, $0.quantity) }
        )
        savedRowIDs = savedRowIDs.intersection(Set(result.rows.map(\.id)))
    }

    private func perform(_ operation: () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
