import Foundation

final class AuthService {

    private let client = APIClient.shared

    func login(
        email: String,
        password: String
    ) async throws -> TokenPairDTO {
        try await client.post(
            endpoint: "/auth/login",
            body: LoginRequestDTO(
                email: email,
                password: password
            ),
            responseType: TokenPairDTO.self
        )
    }

    func refresh(
        refreshToken: String
    ) async throws -> TokenPairDTO {
        try await client.post(
            endpoint: "/auth/refresh",
            body: RefreshRequestDTO(
                refreshToken: refreshToken
            ),
            responseType: TokenPairDTO.self
        )
    }

    func me() async throws -> AuthUserDTO {
        try await client.fetch(
            endpoint: "/auth/me",
            responseType: AuthUserDTO.self
        )
    }

    func logout(refreshToken: String) async throws {
        try await client.send(
            endpoint: "/auth/logout",
            method: "POST",
            body: LogoutRequestDTO(
                refreshToken: refreshToken
            )
        )
    }

    func forgotPassword(email: String) async throws -> ForgotPasswordResponseDTO {
        try await client.post(
            endpoint: "/auth/forgot-password",
            body: ForgotPasswordRequestDTO(email: email),
            responseType: ForgotPasswordResponseDTO.self
        )
    }

    func resetPassword(
        token: String,
        newPassword: String
    ) async throws -> PasswordResetResultDTO {
        try await client.post(
            endpoint: "/auth/reset-password",
            body: ResetPasswordRequestDTO(
                token: token,
                newPassword: newPassword
            ),
            responseType: PasswordResetResultDTO.self
        )
    }
}
