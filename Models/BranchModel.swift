import SwiftUI

struct BranchModel: Identifiable {

    let id = UUID()

    let name: String
    let subtitle: String

    let health: Int

    let breakRisk: Int
    let noRotation: Int
    let overstock: Int

    let color: Color
}
