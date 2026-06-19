import Foundation


@MainActor
final class AlertsViewModel: ObservableObject {

    @Published var alerts: [WarningModel] = []

    @Published var isLoading = false

    @Published var errorMessage: String?

    private let service = AlertsService()

    var criticalAlerts: [WarningModel] {

        alerts.filter { item in

            let text = item.message.lowercased()

            return text.contains("missing")
            || text.contains("outdated")
            || text.contains("error")
            || text.contains("failed")
        }
    }

    var mediumAlerts: [WarningModel] {

        alerts.filter { item in

            !criticalAlerts.contains { critical in
                critical.id == item.id
            }
        }
    }

    var criticalCount: Int {

        criticalAlerts.count
    }

    var mediumCount: Int {

        mediumAlerts.count
    }

    var totalCount: Int {

        alerts.count
    }

    func loadAlerts() async {

        isLoading = true

        errorMessage = nil

        do {

            alerts = try await service.fetchAlerts()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}