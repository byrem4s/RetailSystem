import Foundation

final class AnalysisHistoryService {

    func fetchHistory(
        date: String? = nil
    ) async throws -> AnalysisHistoryResponseDTO {

        var endpoint = "/analysis-history"

        if let date {
            endpoint += "?date=\(date)"
        }

        let response = try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: AnalysisHistoryAPIResponseDTO.self
        )

        return response.data
    }
}