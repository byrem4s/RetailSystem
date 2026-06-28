import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published var response: ReportsResponseDTO?
    @Published var isLoading = false
    @Published var isFileLoading = false
    @Published var errorMessage: String?

    @Published var selectedReportType = "Todos"
    @Published var selectedReportStatus = "Todos"
    @Published var searchText = ""

    @Published var isDateFilterEnabled = false
    @Published var selectedDate = Date()

    let reportTypeOptions = [
        "Todos",
        "Análisis",
        "Pedido F8",
        "F8 confirmado"
    ]

    let reportStatusOptions = [
        "Todos",
        "COMPLETED",
        "GENERATED",
        "FAILED",
        "DRAFT",
        "CONFIRMED"
    ]

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

            response = try await service.fetchReports(
                executionID: AppState.shared.selectedExecutionID,
                reportType: apiReportTypeFilter,
                status: apiStatusFilter,
                date: apiDateFilter,
                search: apiSearchFilter
            )

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

    func applyFilters() async {

        await loadReports()
    }


    func clearFilters() async {

        selectedReportType = "Todos"
        selectedReportStatus = "Todos"
        searchText = ""
        isDateFilterEnabled = false
        selectedDate = Date()

        await loadReports()
    }


    var hasActiveFilters: Bool {

        selectedReportType != "Todos"
        || selectedReportStatus != "Todos"
        || !searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        || isDateFilterEnabled
    }


    private var apiReportTypeFilter: String? {

        selectedReportType == "Todos"
        ? nil
        : selectedReportType
    }


    private var apiStatusFilter: String? {

        selectedReportStatus == "Todos"
        ? nil
        : selectedReportStatus
    }


    private var apiSearchFilter: String? {

        let value = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return value.isEmpty ? nil : value
    }


    private var apiDateFilter: String? {

        guard isDateFilterEnabled else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(
            from: selectedDate
        )
    }
}