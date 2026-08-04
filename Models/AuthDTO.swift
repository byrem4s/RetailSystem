import Foundation

enum UserRole: String, Codable {
    case systemOwner = "SYSTEM_OWNER"
    case companyAdmin = "COMPANY_ADMIN"
    case branchManager = "BRANCH_MANAGER"
    case warehouse = "WAREHOUSE"

    var displayName: String {
        switch self {
        case .systemOwner:
            return "Administrador"
        case .companyAdmin:
            return "Jefe de empresa"
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

    var canViewGlobalIntelligence: Bool {
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
    let mustChangePassword: Bool
    let passwordResetRequestedAt: String?
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
        case mustChangePassword = "must_change_password"
        case passwordResetRequestedAt = "password_reset_requested_at"
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

struct ForgotPasswordRequestDTO: Encodable {
    let email: String
}

struct ForgotPasswordResponseDTO: Decodable {
    let message: String
    let resetToken: String?

    enum CodingKeys: String, CodingKey {
        case message
        case resetToken = "reset_token"
    }
}

struct ResetPasswordRequestDTO: Encodable {
    let token: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case token
        case newPassword = "new_password"
    }
}

struct PasswordResetResultDTO: Decodable {
    let message: String
}

struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
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
