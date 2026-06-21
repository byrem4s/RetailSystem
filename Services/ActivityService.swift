import Foundation

final class ActivityService {

    func fetchActivity() async throws -> ActivityResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: Endpoints.activity,
            responseType: ActivityResponseDTO.self
        )
    }
}