import Foundation
import Combine

@MainActor
final class BranchesViewModel: ObservableObject {

    @Published var response: BranchesResponseDTO?
    @Published var selectedBranchDetail: BranchDetailDTO?
    @Published var selectedBranchID: String?

    @Published var selectedRiskDetail: RiskDetailDTO?

    @Published var isLoading = false
    @Published var isDetailLoading = false
    @Published var isRiskDetailLoading = false
    @Published var isAddingRiskToF8 = false

    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service = BranchesService()
    private let riskDetailService = RiskDetailService()

    var summary: BranchesSummaryDTO? {
        response?.summary
    }

    var ranking: [BranchRankingDTO] {
        response?.ranking ?? []
    }

    var branchesCount: Int {
        summary?.branches ?? 0
    }

    var averageHealth: Int {
        summary?.averageHealth ?? 0
    }

    var highRisk: Int {
        summary?.highRisk ?? 0
    }

    var movements: Int {
        summary?.movements ?? 0
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            let data = try await service.fetchBranches(
                executionID: AppState.shared.selectedExecutionID
            )
            response = data

            if selectedBranchID == nil,
               let firstBranch = data.ranking.first {

                await selectBranch(
                    firstBranch.id
                )

            } else if let selectedBranchID {

                await loadBranchDetail(
                    selectedBranchID
                )
            }

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func selectBranch(
        _ branchID: String
    ) async {

        selectedBranchID = branchID

        await loadBranchDetail(
            branchID
        )
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
        successMessage = nil

        do {

            _ = try await riskDetailService.addRecommendationToF8(
                riskKey: riskKey
            )

            selectedRiskDetail = try await riskDetailService.fetchRiskDetail(
                riskKey: riskKey
            )

            successMessage = "Recomendación agregada al F8 correctamente."

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

    private func loadBranchDetail(
        _ branchID: String
    ) async {

        isDetailLoading = true

        do {

            selectedBranchDetail = try await service.fetchBranchDetail(
                branchID: branchID,
                executionID: AppState.shared.selectedExecutionID
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isDetailLoading = false
    }
}