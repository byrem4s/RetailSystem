import Foundation

@MainActor
final class IntelligenceViewModel: ObservableObject {
    @Published private(set) var dashboard: IntelligenceDashboardDTO?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service = IntelligenceService()

    func load(batchID: Int? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            dashboard = try await service.fetchDashboard(batchID: batchID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

