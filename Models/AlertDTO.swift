import Foundation

struct AlertDTO: Decodable, Identifiable {

    let id = UUID()

    let branch: String

    let barcode: String

    let size: String

    let priority: String

    let reason: String

    let needed: Int
}