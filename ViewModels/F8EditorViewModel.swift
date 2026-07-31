import Foundation

@MainActor
final class F8EditorViewModel: ObservableObject {
    @Published private(set) var rows: [F8RecommendationRowDTO] = []
    @Published private(set) var editable = false
    @Published var quantities: [Int: Int] = [:]
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    let batchID: Int
    private let service = ExcelBatchService()

    init(batchID: Int) {
        self.batchID = batchID
    }

    func load() async {
        await perform {
            apply(try await service.fetchRecommendations(batchID: batchID))
        }
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
        }
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

