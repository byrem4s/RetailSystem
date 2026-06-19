import Foundation

@MainActor
final class BranchesViewModel: ObservableObject {

    @Published var branches: [BranchDTO] = []

    @Published var isLoading = false

    @Published var errorMessage: String?

    private let service = BranchesService()

    func loadData() async {

        isLoading = true

        errorMessage = nil

        do {

            branches = try await service.fetchBranches()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}