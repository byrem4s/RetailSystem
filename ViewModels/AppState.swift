import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    @Published var refreshID = UUID()

    private init() {}

    func refreshSystem() {

        refreshID = UUID()
    }

    func refresh() {

        refreshID = UUID()
    }

    @Published var selectedExecutionID: Int?
    @Published var selectedHistoricalLabel: String?

    var isHistoricalMode: Bool {
        selectedExecutionID != nil
    }

    func selectHistoricalAnalysis(
        executionID: Int,
        label: String
    ) {

        selectedExecutionID = executionID
        selectedHistoricalLabel = label

        refreshSystem()
    }

    func clearHistoricalAnalysis() {

        selectedExecutionID = nil
        selectedHistoricalLabel = nil

        refreshSystem()
    }
}