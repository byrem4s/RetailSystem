import Foundation

final class ReportsService {

    func fetchReports() async throws -> ReportsResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: "/reports",
            responseType: ReportsResponseDTO.self
        )
    }
}