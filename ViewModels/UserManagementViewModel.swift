import Foundation

@MainActor
final class UserManagementViewModel: ObservableObject {

    @Published private(set) var users: [AuthUserDTO] = []
    @Published private(set) var branches: [BranchV2DTO] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service = UserManagementService()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            async let loadedUsers = service.fetchUsers()
            async let loadedBranches = service.fetchBranches()
            users = try await loadedUsers
            let loadedBranchValues = try await loadedBranches
            branches = loadedBranchValues.filter {
                $0.active && !$0.isDepot
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        branchID: Int?
    ) async -> Bool {
        errorMessage = nil
        do {
            let user = try await service.createUser(
                UserCreateRequestDTO(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    role: role,
                    branchID: branchID
                )
            )
            users.insert(user, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func toggle(_ user: AuthUserDTO) async {
        errorMessage = nil
        do {
            let updated = try await service.setActive(
                userID: user.id,
                active: !user.active
            )
            if let index = users.firstIndex(
                where: { $0.id == updated.id }
            ) {
                users[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
