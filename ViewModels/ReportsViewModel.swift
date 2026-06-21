import Foundation

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published var response: ReportsResponseDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = ReportsService()

    var latest: ReportDTO? {
        response?.latest
    }

    var history: [ReportDTO] {
        response?.history ?? []
    }

    var configuration: ReportsConfigurationDTO? {
        response?.configuration
    }

    var scheduleText: String {
        configuration?.schedule ?? "No configurado"
    }

    var notificationsEnabled: Bool {
        configuration?.notifications ?? false
    }

    func loadReports() async {

        isLoading = true
        errorMessage = nil

        do {

            response = try await service.fetchReports()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}