import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var homeData: HomeDTO?

    @Published var isLoading = false
    @Published var isHistoryLoading = false

    @Published var errorMessage: String?
    @Published var historyMessage: String?

    @Published var selectedHistoryDate = Date()
    @Published var historyAnalyses: [AnalysisHistoryItemDTO] = []

    private let service = HomeService()
    private let historyService = AnalysisHistoryService()

    var userName: String {
        homeData?.user.name ?? "Equipo"
    }

    var userBranch: String {
        homeData?.user.branch ?? "Todas las sucursales"
    }

    var recentActivity: [HomeRecentActivityDTO] {
        homeData?.recentActivity ?? []
    }

    var isHistoricalMode: Bool {
        AppState.shared.isHistoricalMode
    }

    var historicalLabel: String? {
        AppState.shared.selectedHistoricalLabel
    }

    func loadData() async {

        isLoading = true
        errorMessage = nil

        do {

            homeData = try await service.fetchHomeData(
                executionID: AppState.shared.selectedExecutionID
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadHistoryForSelectedDate() async {

        isHistoryLoading = true
        errorMessage = nil
        historyMessage = nil
        historyAnalyses = []

        do {

            let dateText = apiDateText(
                selectedHistoryDate
            )

            let response = try await historyService.fetchHistory(
                date: dateText
            )

            let analyses = response.days.first?.analyses ?? []

            if analyses.isEmpty {

                historyMessage = "No hay información para esa fecha. Se mantiene el último análisis disponible."
                historyAnalyses = []

            } else {

                historyAnalyses = analyses
            }

        } catch {

            errorMessage = error.localizedDescription
        }

        isHistoryLoading = false
    }

    func selectHistoricalAnalysis(
        _ item: AnalysisHistoryItemDTO
    ) async {

        let label = "\(displayDateText(item.date)) · \(item.time)"

        AppState.shared.selectHistoricalAnalysis(
            executionID: item.executionID,
            label: label
        )

        await loadData()
    }

    func clearHistoricalMode() async {

        AppState.shared.clearHistoricalAnalysis()

        await loadData()
    }

    private func apiDateText(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(
            from: date
        )
    }

    private func displayDateText(
        _ value: String
    ) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(
            from: value
        ) else {
            return value
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM/yyyy"

        return outputFormatter.string(
            from: date
        )
    }
}