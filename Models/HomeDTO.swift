import Foundation

struct HomeDTO: Decodable {

let pipeline: String

let stockDataset: String

let depositoDataset: String

let salesDataset: String

let stockFreshness: String

enum CodingKeys: String, CodingKey {

    case pipeline

    case stockDataset =
    "stock_dataset"

    case depositoDataset =
    "deposito_dataset"

    case salesDataset =
    "sales_dataset"

    case stockFreshness =
    "stock_freshness"
}

}