import Foundation

final class AlertsService {

    func fetchAlerts(
        executionID: Int? = nil
    ) async throws -> AlertsResponseDTO {

        var endpoint = Endpoints.alerts

        if let executionID {
            endpoint += "?execution_id=\(executionID)"
        }

        return try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: AlertsResponseDTO.self
        )
    }
}