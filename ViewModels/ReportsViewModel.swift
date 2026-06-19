import Foundation
import Combine

@MainActor
final class ReportsViewModel:
ObservableObject {

    @Published var reports:
    [ExportSnapshotModel] = []

    @Published var isLoading =
    false

    @Published var errorMessage:
    String?

    private let service =
    ReportsService()

    func loadReports() async {

        isLoading = true

        do {

            reports =
            try await service.fetchReports()

        } catch {

            errorMessage =
            error.localizedDescription
        }

        isLoading = false
    }
}