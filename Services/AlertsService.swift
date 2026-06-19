import Foundation


final class AlertsService {

    func fetchAlerts() async throws -> [WarningModel] {

        return try await APIClient.shared.fetch(

            endpoint: "/system/warnings",

            responseType: [WarningModel].self
        )
    }
}