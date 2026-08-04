import Foundation

struct BranchV2DTO: Decodable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let isDepot: Bool
    let isSelling: Bool
    let businessGroup: String
    let branchType: String
    let discipline: String
    let salesChannel: String
    let isOutlet: Bool
    let acceptsAdult: Bool
    let acceptsKids: Bool
    let kidsProfile: String
    let workingDays: [Int]
    let demandWeight: Double
    let distanceBand: String
    let returnBlockDays: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case isDepot = "is_depot"
        case isSelling = "is_selling"
        case businessGroup = "business_group"
        case branchType = "branch_type"
        case discipline
        case salesChannel = "sales_channel"
        case isOutlet = "is_outlet"
        case acceptsAdult = "accepts_adult"
        case acceptsKids = "accepts_kids"
        case kidsProfile = "kids_profile"
        case workingDays = "working_days"
        case demandWeight = "demand_weight"
        case distanceBand = "distance_band"
        case returnBlockDays = "return_block_days"
        case active
    }
}

struct UserCreateRequestDTO: Encodable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let role: UserRole
    let branchID: Int?

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case firstName = "first_name"
        case lastName = "last_name"
        case role
        case branchID = "branch_id"
    }
}

struct UserActiveRequestDTO: Encodable {
    let active: Bool
}

struct AdminPasswordResetDTO: Decodable {
    let message: String
    let temporaryPassword: String
    let user: AuthUserDTO

    enum CodingKeys: String, CodingKey {
        case message
        case temporaryPassword = "temporary_password"
        case user
    }
}
