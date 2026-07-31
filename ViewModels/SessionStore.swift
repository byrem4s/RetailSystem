import Foundation

@MainActor
final class SessionStore: ObservableObject {

    @Published private(set) var user: AuthUserDTO?
    @Published private(set) var isRestoring = true
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private let authService = AuthService()
    private let tokenStore = SecureTokenStore.shared

    var isAuthenticated: Bool {
        user != nil && tokenStore.accessToken != nil
    }

    func restoreSession() async {
        defer {
            isRestoring = false
        }
        if let refreshToken = tokenStore.refreshToken {
            do {
                let pair = try await authService.refresh(
                    refreshToken: refreshToken
                )
                try persist(pair)
                return
            } catch {
                tokenStore.clear()
            }
        }
        guard tokenStore.accessToken != nil else {
            user = nil
            return
        }
        do {
            user = try await authService.me()
        } catch {
            tokenStore.clear()
            user = nil
        }
    }

    func login(
        email: String,
        password: String
    ) async {
        isWorking = true
        errorMessage = nil
        defer {
            isWorking = false
        }
        do {
            let pair = try await loginWithDeadline(
                email: email.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                password: password
            )
            try persist(pair)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loginWithDeadline(
        email: String,
        password: String
    ) async throws -> TokenPairDTO {
        let loginTask = Task {
            try await authService.login(
                email: email,
                password: password
            )
        }
        let deadlineTask = Task {
            try await Task.sleep(for: .seconds(12))
            loginTask.cancel()
        }

        defer {
            deadlineTask.cancel()
        }

        do {
            return try await loginTask.value
        } catch {
            if loginTask.isCancelled {
                throw NetworkError.timeout
            }
            throw error
        }
    }

    func logout() async {
        let refreshToken = tokenStore.refreshToken
        tokenStore.clear()
        user = nil
        if let refreshToken {
            try? await authService.logout(
                refreshToken: refreshToken
            )
        }
    }

    func invalidateSession() {
        tokenStore.clear()
        user = nil
    }

    private func persist(_ pair: TokenPairDTO) throws {
        try tokenStore.save(
            accessToken: pair.accessToken,
            refreshToken: pair.refreshToken
        )
        user = pair.user
        errorMessage = nil
    }
}
