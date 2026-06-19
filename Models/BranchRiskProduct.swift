import SwiftUI

struct BranchRiskProduct: Identifiable {

    let id = UUID()

    let name: String

    let status: String
    let stock: String
    let needed: String

    let color: Color
}