import Foundation

final class AlertsService {

    func fetchAlerts() async throws -> AlertsResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: "/alerts",
            responseType: AlertsResponseDTO.self
        )
    }
}