import Foundation

final class BranchesService {

    func fetchBranches() async throws -> BranchesResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: Endpoints.branches,
            responseType: BranchesResponseDTO.self
        )
    }
}