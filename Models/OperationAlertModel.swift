import SwiftUI

struct OperationalAlertModel: Identifiable {

    let id = UUID()

    let title: String
    let subtitle: String

    let branch: String

    let sold: String
    let stock: String
    let velocity: String
    let needed: String

    let risk: String
    let time: String

    let color: Color
    let icon: String

    let description: String
}