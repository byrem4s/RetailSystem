import Foundation

struct WarningModel: Decodable, Identifiable {

let id = UUID()

let message: String

init(message: String) {

    self.message = message
}

init(from decoder: Decoder) throws {

    let container =
    try decoder.singleValueContainer()

    message =
    try container.decode(String.self)
}

}