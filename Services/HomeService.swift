import Foundation

final class HomeService {

    private let api = APIClient.shared

    func fetchHomeData() async throws -> HomeDTO {

        try await api.fetch(
            endpoint: Endpoints.home,
            responseType: HomeDTO.self
        )
    }
}