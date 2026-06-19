import Foundation

final class BranchesService {

    func fetchBranches() async throws -> [BranchDTO] {

        return try await APIClient.shared.fetch(
            endpoint: Endpoints.branches,
            responseType: [BranchDTO].self
        )
    }
}