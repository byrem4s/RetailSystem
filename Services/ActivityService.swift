import Foundation

final class ActivityService {

    func fetchActivity() async throws -> [ActivityDTO] {

        return try await APIClient.shared.fetch(
            endpoint: Endpoints.activity,
            responseType: [ActivityDTO].self
        )
    }
}