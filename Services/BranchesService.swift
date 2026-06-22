import Foundation

final class BranchesService {

    func fetchBranches() async throws -> BranchesResponseDTO {

        try await APIClient.shared.fetch(
            endpoint: Endpoints.branches,
            responseType: BranchesResponseDTO.self
        )
    }

    func fetchBranchDetail(
        branchID: String
    ) async throws -> BranchDetailDTO {

        let encodedBranchID = branchID
            .addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ) ?? branchID

        return try await APIClient.shared.fetch(
            endpoint: "\(Endpoints.branches)/\(encodedBranchID)",
            responseType: BranchDetailDTO.self
        )
    }
}