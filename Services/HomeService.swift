import Foundation

final class HomeService {

    private let api = APIClient.shared

    func fetchHomeData(
        executionID: Int? = nil
    ) async throws -> HomeDTO {

        var endpoint = Endpoints.home

        if let executionID {
            endpoint += "?execution_id=\(executionID)"
        }

        return try await api.fetch(
            endpoint: endpoint,
            responseType: HomeDTO.self
        )
    }
}