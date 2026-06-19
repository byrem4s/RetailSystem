import Foundation

struct ActivityDTO: Decodable, Identifiable {

    let id = UUID()

    let title: String

    let branch: String

    let priority: String

    let reason: String

    let suggested: Int
}