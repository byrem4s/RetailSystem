import SwiftUI

struct ReportModel: Identifiable {

    let id: String

    let fileName: String
    let date: String
    let type: String

    let sheets: String
    let size: String

    let status: String
    let statusColor: Color
}