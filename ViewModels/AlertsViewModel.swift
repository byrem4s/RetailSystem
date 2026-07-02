import Foundation
import Combine

@MainActor
final class AlertsViewModel: ObservableObject {

    @Published var response: AlertsResponseDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = AlertsService()

    var alerts: [AlertDTO] {
        response?.alerts ?? []
    }

    var criticalAlerts: [AlertDTO] {
        alerts.filter {
            $0.priority.uppercased() == "CRITICAL"
        }
    }

    var highAlerts: [AlertDTO] {
        alerts.filter {
            $0.priority.uppercased() == "HIGH"
        }
    }

    var mediumAlerts: [AlertDTO] {
        alerts.filter {
            $0.priority.uppercased() == "MEDIUM"
        }
    }

    var criticalCount: Int {
        response?.summary.critical ?? 0
    }

    var highCount: Int {
        response?.summary.high ?? 0
    }

    var mediumCount: Int {
        response?.summary.medium ?? 0
    }

    var totalCount: Int {
        response?.summary.total ?? 0
    }

    var branchOptions: [String] {

        let branches = Set(
            alerts.map {
                $0.branch
            }
        )

        return ["Todas"] + branches.sorted()
    }

    func loadAlerts() async {

        isLoading = true
        errorMessage = nil

        do {

            response = try await service.fetchAlerts(
                executionID: AppState.shared.selectedExecutionID
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}