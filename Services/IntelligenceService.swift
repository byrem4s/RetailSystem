import Foundation

struct IntelligenceService {
    private let client = APIClient.shared

    func fetchDashboard(batchID: Int? = nil) async throws
        -> IntelligenceDashboardDTO {
        let query = batchID.map { "?batch_id=\($0)" } ?? ""
        return try await client.fetch(
            endpoint: "/v2/intelligence/dashboard\(query)",
            responseType: IntelligenceDashboardDTO.self
        )
    }
}

