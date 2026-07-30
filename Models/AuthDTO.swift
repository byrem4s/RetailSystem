import Foundation

enum UserRole: String, Codable {
    case systemOwner = "SYSTEM_OWNER"
    case companyAdmin = "COMPANY_ADMIN"
    case branchManager = "BRANCH_MANAGER"
    case warehouse = "WAREHOUSE"

    var displayName: String {
        switch self {
        case .systemOwner:
            return "Propietario del sistema"
        case .companyAdmin:
            return "Administrador"
        case .branchManager:
            return "Encargado de sucursal"
        case .warehouse:
            return "Depósito"
        }
    }

    var canApproveTransfers: Bool {
        self == .systemOwner
        || self == .companyAdmin
        || self == .warehouse
    }

    var canModifyQuantities: Bool {
        canApproveTransfers
    }

    var canViewLegacyDashboard: Bool {
        self == .systemOwner || self == .companyAdmin
    }
}

struct AuthUserDTO: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let branchID: Int?
    let active: Bool
    let protected: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case role
        case branchID = "branch_id"
        case active
        case protected
        case createdAt = "created_at"
    }

    var fullName: String {
        "\(firstName) \(lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct RefreshRequestDTO: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct LogoutRequestDTO: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct TokenPairDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let accessExpiresAt: String
    let user: AuthUserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case accessExpiresAt = "access_expires_at"
        case user
    }
}
