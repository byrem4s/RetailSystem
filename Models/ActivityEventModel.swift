import SwiftUI

struct ActivityEventModel: Identifiable {

    let id = UUID()

    let title: String
    let subtitle: String
    let branch: String

    let status: String
    let reason: String

    let origin: String
    let destination: String

    let time: String

    let color: Color
    let icon: String
}