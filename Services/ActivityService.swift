import Foundation

final class ActivityService {

    func fetchActivity(
        executionID: Int? = nil
    ) async throws -> ActivityResponseDTO {

        var endpoint = Endpoints.activity

        if let executionID {
            endpoint += "?execution_id=\(executionID)"
        }

        return try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: ActivityResponseDTO.self
        )
    }
}