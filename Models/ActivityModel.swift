import SwiftUI

struct ActivityModel: Identifiable {

    let id = UUID()

    let icon: String
    let color: Color

    let title: String
    let description: String
    let detail: String
    let time: String
}