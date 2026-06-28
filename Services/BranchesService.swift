import Foundation

final class BranchesService {

    func fetchBranches(
        executionID: Int? = nil
    ) async throws -> BranchesResponseDTO {

        var endpoint = Endpoints.branches

        if let executionID {
            endpoint += "?execution_id=\(executionID)"
        }

        return try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: BranchesResponseDTO.self
        )
    }

    func fetchBranchDetail(
        branchID: String,
        executionID: Int? = nil
    ) async throws -> BranchDetailDTO {

        var endpoint = "\(Endpoints.branches)/\(branchID)"

        if let executionID {
            endpoint += "?execution_id=\(executionID)"
        }

        return try await APIClient.shared.fetch(
            endpoint: endpoint,
            responseType: BranchDetailDTO.self
        )
    }
}