import Foundation
import Combine

@MainActor
final class BranchesViewModel: ObservableObject {

    @Published var response: BranchesResponseDTO?
    @Published var selectedBranchDetail: BranchDetailDTO?
    @Published var selectedBranchID: String?
    @Published var isLoading = false
    @Published var isDetailLoading = false
    @Published var errorMessage: String?

    private let service = BranchesService()

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

            let data = try await service.fetchBranches()

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

    private func loadBranchDetail(
        _ branchID: String
    ) async {

        isDetailLoading = true

        do {

            selectedBranchDetail = try await service.fetchBranchDetail(
                branchID: branchID
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isDetailLoading = false
    }
}