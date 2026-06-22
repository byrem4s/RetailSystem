import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published var response: ReportsResponseDTO?
    @Published var isLoading = false
    @Published var isFileLoading = false
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

    func downloadReportFile(
        _ report: ReportDTO
    ) async -> URL? {

        isFileLoading = true
        errorMessage = nil

        do {

            let url = try await service.downloadReport(
                report
            )

            isFileLoading = false

            return url

        } catch {

            errorMessage = error.localizedDescription
            isFileLoading = false

            return nil
        }
    }
}