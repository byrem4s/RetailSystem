import Foundation

struct BranchV2DTO: Decodable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let isDepot: Bool
    let distanceBand: String
    let returnBlockDays: Int
    let active: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
        case isDepot = "is_depot"
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
