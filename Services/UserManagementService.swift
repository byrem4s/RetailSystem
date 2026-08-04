import Foundation

final class UserManagementService {

    private let client = APIClient.shared

    func fetchUsers() async throws -> [AuthUserDTO] {
        try await client.fetch(
            endpoint: "/v2/users",
            responseType: [AuthUserDTO].self
        )
    }

    func fetchBranches() async throws -> [BranchV2DTO] {
        try await client.fetch(
            endpoint: "/v2/branches",
            responseType: [BranchV2DTO].self
        )
    }

    func createUser(
        _ request: UserCreateRequestDTO
    ) async throws -> AuthUserDTO {
        try await client.post(
            endpoint: "/v2/users",
            body: request,
            responseType: AuthUserDTO.self
        )
    }

    func setActive(
        userID: Int,
        active: Bool
    ) async throws -> AuthUserDTO {
        try await client.executePatch(
            endpoint: "/v2/users/\(userID)/active",
            body: UserActiveRequestDTO(active: active),
            responseType: AuthUserDTO.self
        )
    }


    func resetPassword(userID: Int) async throws -> AdminPasswordResetDTO {
        try await client.post(
            endpoint: "/v2/users/\(userID)/reset-password",
            responseType: AdminPasswordResetDTO.self
        )
    }
}
