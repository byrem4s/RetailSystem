import Foundation

@MainActor
final class BranchesViewModel: ObservableObject {

    @Published var response: BranchesResponseDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = BranchesService()

    var summary: BranchesSummaryDTO? {
        response?.summary
    }

    var ranking: [BranchRankingDTO] {
        response?.ranking ?? []
    }

    var selectedBranch: SelectedBranchDTO? {
        response?.selectedBranch
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

            response = try await service.fetchBranches()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}