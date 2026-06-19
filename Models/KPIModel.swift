import SwiftUI

struct KPIModel: Identifiable {

    let id = UUID()

    let icon: String
    let color: Color

    let value: String

    let title: String
    let subtitle: String
}