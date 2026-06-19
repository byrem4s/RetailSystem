import Foundation


final class ReportsService {

    func fetchReports()
    async throws -> [ExportSnapshotModel] {

        return try await APIClient.shared.fetch(

            endpoint: "/exports/history",

            responseType:
            [ExportSnapshotModel].self
        )
    }
}