import Foundation
import Combine

@MainActor
final class ActivityViewModel: ObservableObject {

    @Published var activities: [ActivityDTO] = []

    @Published var isLoading = false

    @Published var errorMessage: String?

    private let service = ActivityService()

    func loadData() async {

        isLoading = true

        errorMessage = nil

        do {

            activities = try await service.fetchActivity()

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}