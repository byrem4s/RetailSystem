import Foundation
import Combine

@MainActor
final class AlertsViewModel: ObservableObject {

    @Published var response: AlertsResponseDTO?

    @Published var selectedRiskDetail: RiskDetailDTO?

    @Published var isLoading = false
    @Published var isRiskDetailLoading = false
    @Published var isAddingRiskToF8 = false

    @Published var errorMessage: String?

    private let service = AlertsService()
    private let riskDetailService = RiskDetailService()

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

    func openRiskDetail(
        riskKey: String
    ) async {

        isRiskDetailLoading = true
        errorMessage = nil

        do {

            selectedRiskDetail = try await riskDetailService.fetchRiskDetail(
                riskKey: riskKey
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isRiskDetailLoading = false
    }


    func addRiskRecommendationToF8(
        riskKey: String
    ) async {

        if AppState.shared.isHistoricalMode {
            errorMessage = "No se puede modificar el F8 desde el modo histórico."
            return
        }

        isAddingRiskToF8 = true
        errorMessage = nil

        do {

            _ = try await riskDetailService.addRecommendationToF8(
                riskKey: riskKey
            )

            selectedRiskDetail = try await riskDetailService.fetchRiskDetail(
                riskKey: riskKey
            )

            errorMessage = "Recomendación agregada al F8 correctamente."

            AppState.shared.refreshSystem()

        } catch {

            errorMessage = userFriendlyF8Error(
                from: error
            )
        }

        isAddingRiskToF8 = false
    }


    private func userFriendlyF8Error(
        from error: Error
    ) -> String {

        let message = error.localizedDescription.lowercased()

        if message.contains("409")
            || message.contains("conflict")
            || message.contains("already")
            || message.contains("duplic")
            || message.contains("ya fue")
            || message.contains("ya existe") {

            return "Este producto ya fue agregado al F8."
        }

        if message.contains("origen")
            || message.contains("stock")
            || message.contains("disponible") {

            return "No hay origen o stock disponible para agregar esta recomendación al F8."
        }

        return error.localizedDescription
    }
}